window.Element ||= {}
class Element.GoogleChart

  constructor:  (@container_id)->
    return this

  draw: (options)->
    @container = $("#account_#{@container_id}").parent()
    @node = $("#account_#{@container_id}")

    @chart = new google.visualization.ComboChart(@node[0])
    @options =
      chartArea: {width: '80%', height: '70%'},
      width: @container.width()
      height: @container.height()
      backgroundColor:
        fill:'transparent'
      legend:
        position: options.legend_position
      animation:
        duration: 500,
        easing: 'out',

      hAxis:
        slantedText: false
        title: options.title
        showTextEvery: options.haxis_ticks
        textPosition: 'out'
        textStyle:
            bold: true
            color: 'black'
      vAxis:
        textStyle:
            bold: true
            fontSize: 12,
            color: 'black'

      seriesType: 'bars',
      series: {1: {type: 'line'}}

    @data = google.visualization.arrayToDataTable options.points
    @chart.draw @data, @options
