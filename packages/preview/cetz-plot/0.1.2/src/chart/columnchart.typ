#import "/src/cetz.typ": draw, styles, palette, util, vector, intersection

#import "/src/plot.typ"

#let columnchart-default-style = (
  axes: (tick: (length: 0), grid: (stroke: (dash: "dotted"))),
  bar-width: .8,
  cluster-gap: 0,
  error: (
    whisker-size: .25,
  ),
  x-inset: 1,
)

/// Draw a column chart. A column chart is a chart that represents data with
/// rectangular bars that grow from bottom to top, proportional to the values
/// they represent.
///
/// === Styling
/// *Root*: `columnchart`.
/// #show-parameter-block("bar-width", "float", default: .8, [
///   Width of a single bar (basic) or a cluster of bars (clustered) in the plot.])
/// #show-parameter-block("x-inset", "float", default: 1, [
///   Distance of the plot data to the plot's edges on the x-axis of the plot.])
/// You can use any `plot` or `axes` related style keys, too.
///
/// The `columnchart` function is a wrapper of the `plot` API. Arguments passed
/// to `..plot-args` are passed to the `plot.plot` function.
///
/// - data (array): Array of data rows. A row can be of type array or
///                 dictionary, with `label-key` and `value-key` being
///                 the keys to access a rows label and value(s).
///
///                 *Example*
///                 ```typc
///                 (([A], 1), ([B], 2), ([C], 3),)
///                 ``` 
/// - label-key (int,string): Key to access the label of a data row.
///                           This key is used as argument to the
///                           rows `.at(..)` function.
/// - value-key (int,string): Key(s) to access value(s) of data row.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - error-key (none,int,string,array): Key(s) to access error values of a data row.
///     These keys are used as argument to the rows `.at(..)` function.
/// - mode (string): Chart mode:
///   / basic: Single bar per data row
///   / clustered: Group of bars per data row
///   / stacked: Stacked bars per data row
///   / stacked100: Stacked bars per data row relative
///     to the sum of the row
/// - size (array): Chart size as width and height tuple in canvas unist;
///                 width can be set to `auto`.
/// - bar-style (style,function): Style or function (idx => style) to use for
///   each bar, accepts a palette function.
/// - y-label (content,none): Y axis label
/// - x-label (content,none): x axis label
/// - labels (none,content): Legend labels per y value group
/// - ..plot-args (any): Arguments to pass to `plot.plot`
#let columnchart(data,
                 label-key: 0,
                 value-key: 1,
                 error-key: none,
                 mode: "basic",
                 size: (auto, 1),
                 bar-style: palette.red,
                 x-label: none,
                 y-format: auto,
                 y-label: none,
                 labels: none,
                 ..plot-args
                 ) = {
  assert(type(label-key) in (int, str))
  if mode == "basic" {
    assert(type(value-key) in (int, str))
  }

  if type(value-key) != array {
    value-key = (value-key,)
  }

  if error-key == none {
    error-key = ()
  } else if type(error-key) != array {
    error-key = (error-key,)
  }

  if type(size) != array {
    size = (auto, size)
  }
  if size.at(0) == auto {
    size.at(0) = (data.len() + 1)
  }

  let x-tic-list = data.enumerate().map(((i, t)) => {
    (i, t.at(label-key))
  })

  let y-format = y-format
  if y-format == auto {
    y-format = if mode == "stacked100" {plot.formats.decimal.with(suffix: [%])} else {auto}
  }

  data = data.enumerate().map(((i, d)) => {
    (i, value-key.map(k => d.at(k)).flatten(), error-key.map(k => d.at(k, default: 0)).flatten())
  })

  draw.group(ctx => {
    let style = styles.resolve(ctx.style, merge: (:),
      root: "columnchart", base: columnchart-default-style)
    draw.set-style(..style)

    let x-inset = calc.max(style.x-inset, style.bar-width / 2)
    plot.plot(size: size,
              axis-style: "scientific-auto",
              y-grid: true,
              y-label: y-label,
              y-format: y-format,
              x-min: -x-inset,
              x-max: data.len() + x-inset - 1,
              x-tick-step: none,
              x-ticks: x-tic-list,
              x-label: x-label,
              plot-style: bar-style,
              ..plot-args,
    {
      plot.add-bar(data,
        x-key: 0,
        y-key: 1,
        error-key: if mode in ("basic", "clustered") { 2 },
        mode: mode,
        labels: labels,
        bar-width: style.bar-width,
        cluster-gap: style.cluster-gap,
        error-style: style.error,
        whisker-size: style.error.whisker-size,
        axes: ("x", "y"))
    })
  })
}
