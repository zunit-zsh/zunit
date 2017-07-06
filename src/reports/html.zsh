#########################################
# Functions for handling HTML reporting #
#########################################

###
# The head of the HTML document used to display results
###
function _zunit_html_header() {
  echo '<!DOCTYPE html> <html lang="en"> <head> <meta charset="UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1.0"> <meta http-equiv="X-UA-Compatible" content="ie=edge"> <title>ZUnit Test Results</title> <link href="https://fonts.googleapis.com/css?family=Fira+Mono" rel="stylesheet"> <style> html, body, div, span, applet, object, iframe, h1, h2, h3, h4, h5, h6, p, blockquote, pre, a, abbr, acronym, address, big, cite, code, del, dfn, em, img, ins, kbd, q, s, samp, small, strike, strong, sub, sup, tt, var, b, u, i, center, dl, dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody, tfoot, thead, tr, th, td, article, aside, canvas, details, embed, figure, figcaption, footer, header, hgroup, main, menu, nav, output, ruby, section, summary, time, mark, audio, video { margin: 0; padding: 0; border: 0; font-size: 100%; font: inherit; vertical-align: baseline; box-sizing: border-box; } /* HTML5 display-role reset for older browsers */ article, aside, details, figcaption, figure, footer, header, hgroup, main, menu, nav, section { display: block; } body { line-height: 1; } ol, ul { list-style: none; } blockquote, q { quotes: none; } blockquote:before, blockquote:after, q:before, q:after { content: ""; content: none; } table { border-collapse: collapse; border-spacing: 0; } html { font: 100%/1.5em "Fira Code", "Fira Mono", monospace} body { line-height: 1.5em; color: #394648; font-size: 1.125em; } h1, h2, h3, h4, h5, h6 { font-weight: 700; } h1 { font-size: 3em; line-height: 1em; margin-bottom: 0.5em; } h2 { font-size: 2.25em; line-height: 1.35em; margin-bottom: 0.66667em; } h3 { font-size: 1.5em; line-height: 1em; margin-bottom: 1em; } h4 { font-size: 1.3125em; line-height: 1.14286em; margin-bottom: 1.14286em; } h5 { font-size: 1.125em; line-height: 1.35em; margin-bottom: 1.33333em; } h6 { font-size: 1em; line-height: 1.5em; margin-bottom: 1.5em; } p.lead { font-size: 1.5em; } p, ul, ol, dl, blockquote { margin-bottom: 1.5em; } ul { list-style: disc inside; } ol { list-style: decimal inside; } ul ul, ol ul { list-style: circle inside; margin-bottom: 0; margin-left: 1.5em; } ul ol, ol ol { list-style: lower-roman inside; margin-bottom: 0; margin-left: 1.5em; } em { font-style: italic; } strong { font-weight: 700; } small { font-size: .75em; line-height: .5em; } hr { height: 0; margin: calc(3em - 1px) auto 3em; border: solid rgba(53, 12, 16, 0.05); border-width: 0 0 1px; } a { color: #4897da; text-decoration: none; } blockquote, figcaption { display: block; } pre { margin: 0 0 1.5em; } code { font-family: "Fira Code", "Courier New", "Inconsolata", monospace; line-height: 0; } body { padding: 3em 1.5em; } @media (min-width: 36em) { body { padding: 3em; } } @media (min-width: 60em) { body { padding: 3em 6em; } } .header { border-bottom: 1px solid rgba(0,0,0,.1); margin-bottom: 3em; } .header--nav a, .header--nav span { margin-right: 1.5em; } .main { display: flex; } .results { flex: 0 1 100%; padding-right: 15em; } .sidebar--nav { flex: 0 0 12em; position: fixed; right: 6em; top: 7.5em; width: 12em; } .results { list-style: none; } .results--item { border-radius: .15em; display: none; padding: 0 .75em; } .results--item.visible { display: block; } .results--item.expanded { border: 1px solid rgba(0,0,0,.1); margin: 0 0 .375em; } .results--item span { display: none; } .results--item.expanded span { display: block; } .results--item pre { display: none; font-size: .75em; margin: 0; padding: 0; } .results--item.expanded pre { display: block; } .results--item h6 { line-height: 2.25em; margin: 0; } .results--item h6::before { box-sizing: border-box; display: inline-block; margin-right: .375em; vertical-align: middle; } .results--item:not(.passed) h6::after { content: "+"; float: right; } .results--item:not(.passed).expanded h6::after { content: "⌃"; } .results--item.passed h6::before { color: #4ecdc4; content: "✔"; } .results--item.failed h6 { color: #ff6b6b; } .results--item.failed h6::before { color: #ff6b6b; content: "✘"; } .results--item.error { background: #b23939; color: #fff; } .results--item.error h6::before { content: "‼"; } .results--item.warning h6::before { color: #dccb80; content: "‼"; } .results--item.skipped h6::before { color: #d567c6; content: "•"; } .sidebar--nav ul { list-style: none; } .sidebar--nav-item { background: rgba(0,0,0,.1); border-radius: .15em; margin-bottom: .375em; padding: .375em .75em; } .sidebar--nav-item_total, .sidebar--nav-item_elapsed { padding: 0 .75em; } .sidebar--nav-item_elapsed { margin-bottom: 1.5em; } .sidebar--nav-item-count { float: right; font-weight: 700; } .sidebar--nav-item_all.selected { background: #4897da; color: #fff; } .sidebar--nav-item_passed.selected { background: #4ecdc4; color: #fff; } .sidebar--nav-item_failed.selected { background: #ff6b6b; color: #fff; } .sidebar--nav-item_errors.selected { background: #b23939; color: #fff; } .sidebar--nav-item_skipped.selected { background: #d567c6; color: #fff; } .sidebar--nav-item_warnings.selected { background: #dccb80; } </style> <script>;(function() { "use strict"; window.addEventListener("DOMContentLoaded", function() { var results = document.querySelectorAll(".results--item"), links = document.querySelectorAll(".sidebar--nav-item"); var hideAll = function(evt) { for (var i = 0; i < links.length; i++) { (function(link) { if (link.classList.contains("sidebar--nav-item_all")) { return; } if (!link.classList.contains("selected")) { link.classList.add("selected"); } toggleVisibility({currentTarget: link}) }(links[i])); } }; var showAll = function(evt) { for (var i = 0; i < links.length; i++) { (function(link) { if (link.classList.contains("sidebar--nav-item_all")) { return; } if (link.classList.contains("selected")) { link.classList.remove("selected"); } toggleVisibility({currentTarget: link}); }(links[i])); } }; var allLinksAreVisible = function() { var visible = true; for (var i = 0; i < links.length; i++) { if (!links[i].classList.contains("sidebar--nav-item_all") && !links[i].classList.contains("selected")) { visible = false; } } return visible; }; var toggleVisibility = function(evt) { evt = evt || window.evt; var link = evt.currentTarget, target = link.dataset.target; if (link.classList.contains("selected")) { link.classList.remove("selected"); if (link.classList.contains("sidebar--nav-item_all")) { hideAll(); } else { document.querySelector(".sidebar--nav-item_all").classList.remove("selected"); } } else { link.classList.add("selected"); if (link.classList.contains("sidebar--nav-item_all")) { showAll(); } else { if (allLinksAreVisible()) { document.querySelector(".sidebar--nav-item_all").classList.add("selected"); } } } for (var i = 0; i < results.length; i++) { (function(result) { if (result.classList.contains(target)) { if (link.classList.contains("selected")) { result.classList.add("visible"); } else { result.classList.remove("visible"); } } }(results[i])); } }; var toggleResultExpansion = function(evt) { evt = evt || window.event; var result = evt.currentTarget; if (result.classList.contains("expanded")) { result.classList.remove("expanded"); } else { result.classList.add("expanded"); } }; for (var i = 0; i < results.length; i++) { (function(result) { if (!result.classList.contains("passed")) { result.addEventListener("click", toggleResultExpansion, true); } }(results[i])); }; for (var i = 0; i < links.length; i++) { (function(link) { link.addEventListener("click", toggleVisibility, true); }(links[i])); }; }); })();</script> </head> <body> <header class="header"> <nav class="header--nav"> <span>ZUnit Test Results</span> <a href="https://github.com/zunit-zsh/zunit">Documentation</a> </nav> </header> <main role="main" class="main"> <ul class="results">'
}

###
# The footer of the HTML document used to display results
###
function _zunit_html_footer() {
  integer elapsed=$(( end_time - start_time ))
  output="</ul> <nav class='sidebar--nav'> <ul> <li class='sidebar--nav-item_total'><strong>$total</strong> tests run</li> <li class='sidebar--nav-item_elapsed'>taking <strong>$(_zunit_human_time $elapsed)</strong></li> <li class='sidebar--nav-item sidebar--nav-item_all selected'> All <span class='sidebar--nav-item-count'>$total</span> </li> <li class='sidebar--nav-item sidebar--nav-item_passed selected' data-target='passed'> Passed <span class='sidebar--nav-item-count'>$passed</span> </li> <li class='sidebar--nav-item sidebar--nav-item_failed selected' data-target='failed'> Failed <span class='sidebar--nav-item-count'>$failed</span> </li> <li class='sidebar--nav-item sidebar--nav-item_errors selected' data-target='error'> Errors <span class='sidebar--nav-item-count'>$errors</span> </li> <li class='sidebar--nav-item sidebar--nav-item_warnings selected' data-target='warning'> Warnings <span class='sidebar--nav-item-count'>$warnings</span> </li> <li class='sidebar--nav-item sidebar--nav-item_skipped selected' data-target='skipped'> Skipped <span class='sidebar--nav-item-count'>$skipped</span> </li> </ul> </nav> </main> </body> </html>"
  echo $output
}

###
# Output a HTML success message
###
_zunit_html_success() {
  echo "<li class='results--item passed visible'>
    <h6>$name</h6>
  </li>"
}

###
# Output a HTML failure message
###
_zunit_html_failure() {
  echo "<li class='results--item failed visible'>
    <h6>$name</h6>
    <pre><code>$message</code></pre>
  </li>"
}

###
# Output a HTML error message
###
_zunit_html_error() {
  echo "<li class='results--item error visible'>
    <h6>$name</h6>
    <pre><code>$message</code></pre>
  </li>"
}

###
# Output a HTML warning message
###
_zunit_html_warn() {
  echo "<li class='results--item warning visible'>
    <h6>$name</h6>
    <span class='results--item_warning'>$message</span>
  </li>"
}

###
# Output a HTML skipped test message
###
_zunit_html_skip() {
  echo "<li class='results--item skipped visible'>
    <h6>$name</h6>
    <span class='results--item_skip-reason'>$message</span>
  </li>"
}

###
# Output a HTML fatal error message
###
_zunit_html_fatal_error() {
  message="$@"
  echo "<li class='results--item error fatal visible'>
    <h6>$message</h6>
  </li>"
}
