window.Element ||= {}
class Element.GoogleChart

  constructor:  (@container_id)->
    return this

  draw: (options)->
    @container = $("#account_#{@container_id}").parent()
    @node = $("#account_#{@container_id}")

    @chart = new google.visualization.ColumnChart(@node[0])
    @options =
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
        slantedTextAngle: 45
        showTextEvery: 2
        textStyle:
            bold: true
            color: 'black'
      vAxis:
        textStyle:
            bold: true
            fontSize: 12,
            color: 'black'

    @data = google.visualization.arrayToDataTable options.points
    @chart.draw @data, @options
