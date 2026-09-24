// Shared typography and spacing. The compact preset accommodates longer CVs.
#let layout(compact: false, leading: none) = {
  let blue = rgb("237eb0")
  let line-gap = if leading != none { leading } else if compact { 5.2pt } else { 8pt }
  let render(body) = {
    set document(title: "Nicholas Junge — CV", author: "Nicholas Junge")
    set page(paper: "a4", margin: (x: 12mm, y: 12mm))
    set text(font: "Georgia", size: 10pt, lang: "en")
    set par(leading: line-gap, spacing: 0pt, justify: false)
    show link: it => underline(text(fill: blue, it))
    body
  }
  let header(summary: none) = block(below: 0pt)[
    #text(size: 17pt, weight: "bold", fill: blue)[Nicholas Junge]
    #v(10pt)
    #grid(
      columns: (auto, 1fr, auto, 1fr, auto, 1fr, auto, 1fr, auto),
      [Munich, DE], align(center)[|],
      link("mailto:nicho.junge@gmail.com")[#text("nicho.junge@gmail.com")], align(center)[|],
      link("https://nicholasjunge.com")[https://nicholasjunge.com], align(center)[|],
      link("https://www.linkedin.com/in/nicholas-junge/")[LinkedIn], align(center)[|],
      link("https://github.com/nicholasjng/")[GitHub],
    )
    #if summary != none [#v(14pt)#summary]
  ]
  let section(title) = block(above: if compact { 14pt } else { 19pt }, below: 8pt, sticky: true)[
    #text(size: 11.5pt, weight: "bold", fill: blue)[#title]
    #v(6pt)
    #line(length: 100%, stroke: 0.7pt + blue)
  ]
  let entry(title, date, body, tools: none, first: false) = block(
    above: if first { 8pt } else if compact { 12pt } else { 20pt },
    below: 0pt, breakable: false,
  )[
    #grid(columns: (1fr, auto), column-gutter: 8pt,
      strong(title), align(right, strong(date)))
    #v(if compact { 6pt } else { 7pt })
    #body
    #if tools != none [
      #v(8pt)
      *Tools:* #emph(tools)
    ]
  ]
  let bullets(..items) = {
    set list(indent: 0pt, body-indent: 5pt, tight: false,
      spacing: if compact { 7pt } else { 12pt })
    list(..items.pos())
  }
  (document: render, header: header, section: section, entry: entry, bullets: bullets)
}
