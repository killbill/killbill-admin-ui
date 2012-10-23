// Inspired by http://bl.ocks.org/2579599
// This function assumes the data to be sorted
// TODO: add Y legend, add labels on data points
function drawGraph(dataX, dataY, chartId) {
  if (dataX.length != dataY.length) {
    return;
  }

  // Define dimensions of graph
  var m = [80, 80, 80, 80];   // margins
  var w = 1000 - m[1] - m[3]; // width
  var h = 400 - m[0] - m[2];  // height

  // For regular data (non dates):
  //var x = d3.scale.linear().domain([0, dataX.length]).range([0, w]);
  // For dates:
  var minDate = new Date(dataX[0]);
  var maxDate = new Date(dataX[dataX.length - 1]);
  var x = d3.time.scale().domain([minDate, maxDate]).range([0, w]);

  // Y scale will fit values from 0-yMax within pixels h-0 (Note the inverted domain for the y-scale: bigger is up!)
  var yMin = d3.min(dataY);
  if (yMin > 0) {
    yMin = 0;
  }
  var yMax = d3.max(dataY);
  var y = d3.scale.linear().domain([yMin, yMax]).range([h, 0]);

  // Create a line function that can convert data[] into x and y points
  var line = d3.svg.line()
    .x(function(d,i) {
      // For regular data (non dates):
      //console.log('Plotting X value for data point: ' + d + ' using index: ' + i + ' to be at: ' + x(dataX[i]) + ' using our xScale.');
      //return x(dataX[i]);
      // For dates
      //console.log('Plotting X value for data point: ' + d + ' using index: ' + i + ' to be at: ' + x(new Date(dataX[i])) + ' using our xScale.');
      return x(new Date(dataX[i]));
    })
    .y(function(d) {
      //console.log('Plotting Y value for data point: ' + d + ' to be at: ' + y(d) + " using our yScale.");
      return y(d);
    })

    // Add an SVG element with the desired dimensions and margin.
    var graph = d3.select("#" + chartId)
                  .append("svg:svg")
                    .attr("width", w + m[1] + m[3])
                    .attr("height", h + m[0] + m[2])
                  .append("svg:g")
                    .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

    // Create xAxis
    var xAxis = d3.svg.axis().scale(x).tickSize(-h).tickSubdivide(true);
    // Add the x-axis
    graph.append("svg:g")
           .attr("class", "x axis")
           .attr("transform", "translate(0," + h + ")")
         .call(xAxis);

    // Create left yAxis
    var yAxisLeft = d3.svg.axis().scale(y).ticks(4).orient("left");
    // Add the y-axis to the left
    graph.append("svg:g")
           .attr("class", "y axis")
           .attr("transform", "translate(-25,0)")
         .call(yAxisLeft);

    // Add the line by appending an svg:path element with the data line we created above
    // do this AFTER the axes above so that the line is above the tick-lines
    graph.append("svg:path").attr("d", line(dataY));
}