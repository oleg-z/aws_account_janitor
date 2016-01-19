window.App ||= {}
class App.Janitor extends App.Base

  beforeAction: (action) =>
    return


  afterAction: (action) =>
    return


  usage_dashboard: =>
    for k,v of Utility.RailsVars.usage_data
        points = [["Date", "$/day", { role: "style" } ]]
        for date, cost of v
            color = true ? '#008000' : '#008000'
            d = new Date(date)
            points.push(["#{d.getMonth()+1}/#{d.getUTCDate()}", parseInt(cost), "color: #{color}"])


        new Element.GoogleChart(k).draw(points: points, legend_position: 'none')
    return
