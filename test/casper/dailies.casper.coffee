helper = new require('./test/casper/helpers')()
casper = helper.casper
utils = helper.utils
url = helper.url

casper.start url + '/?play=1'

# ---------- Daily ------------
casper.then ->
  helper.reset()
  helper.addTasks()

# Gained exp on +daily
casper.then ->
  user = helper.userBeforeAfter (-> casper.click '.dailys input[type="checkbox"]')
  @test.assertEquals user.before.stats.hp, user.after.stats.hp, '+daily =hp'
  @test.assert user.before.stats.exp < user.after.stats.exp, '+daily +exp'
  @test.assert user.before.stats.money < user.after.stats.money, '+daily +money'

# -daily acts as undo
casper.then ->
  user = helper.userBeforeAfter (-> casper.click '.dailys input[type="checkbox"]')
  @test.assertEquals user.before.stats.hp, user.after.stats.hp, '-daily =hp'
  @test.assert user.before.stats.exp > user.after.stats.exp, '-daily -exp'
  @test.assert user.before.stats.money > user.after.stats.money, '-daily -money'

# ---------- Cron ------------

casper.then ->
  helper.reset()
  helper.addTasks()

casper.then ->
  user = {before:helper.getUser()}
  tasks =
    before:
      daily: @evaluate -> window.DERBY.app.model.get('_dailyList')
      todo: @evaluate -> window.DERBY.app.model.get('_todoList')
  helper.runCron()

  @then ->
    @wait 1050, -> # user's hp is updated after 1s for animation
      user.after = helper.getUser()
      @test.assertEqual user.before.id, user.after.id, 'user id equal after cron'
      tasks.after =
          daily: @evaluate -> window.DERBY.app.model.get('_dailyList')
          todo: @evaluate -> window.DERBY.app.model.get('_todoList')

      @test.assertEqual user.before.tasks.length, user.after.tasks.length, "Didn't lose anything on cron"

      #TODO make sure true for all dailies
      dailyId = tasks.before.daily[0].id
      utils.dump tasks.before.daily
      utils.dump
        dailyBefore:user.before.tasks[dailyId].value
        dailyAfter:user.before.tasks[dailyId].value
      @test.assert user.before.tasks[dailyId].value < user.before.tasks[dailyId].value, "todo gained value on cron"
      @test.assert user.before.stats.hp < user.after.stats.hp, 'user lost HP on cron'

      #TODO make sure true for all todos
      todoId = tasks.before.todo[0].id
      @test.assert user.before.tasks[todoId].value < user.before.tasks[todoId].value, "todo gained value on cron"

# ---------- Run ------------

casper.run ->
  @test.renderResults true