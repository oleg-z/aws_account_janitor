window.App ||= {}
class App.Dashboard extends App.Base

  beforeAction: (action) =>
    return


  afterAction: (action) =>
    return


  usage_dashboard: =>
    for account,v of Utility.RailsVars.usage_data
        points = [["Date", "$/day", "Threshold", { role: "style" } ]]
        for date, cost of v.spending
            color = true ? '#008000' : '#008000'
            d = new Date(date)
            points.push(["#{d.getUTCMonth()+1}/#{d.getUTCDate()}", parseInt(cost), parseInt(v.threshold), "color: #{color}"])

        new Element.GoogleChart(account).draw(points: points, legend_position: 'none', haxis_ticks: Math.ceil(points.length/8))
    return
