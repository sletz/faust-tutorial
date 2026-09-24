// Block diagrams that can be explored inside the page.
//
// scripts/build_docs.py writes each diagram as
//
//   <div class="faust-diagram-box" data-src="../examples/NN/name-svg/process.svg">
//     <a class="faust-diagram-link" href="..." target="_blank"><img class="faust-diagram" ...></a>
//   </div>
//
// which, without this script, shows the top-level diagram and opens it in a
// new tab. This script replaces the link and the image by the SVG itself,
// inserted in the page, so that a click on a box (an <a> of the SVG drawn by
// `faust -svg`) shows that box's diagram in place, and adds a bar above it:
//
//   - the path from the top level (process › osc › phasor), each level
//     clickable to go back up (the title of a sub-diagram, which links to its
//     parent, goes back up the same way);
//   - "open in a new tab", for the diagram shown: a large diagram is easier
//     to read there, at its full size.
//
// A click with a modifier (Ctrl, Cmd, Shift) or the middle button is left to
// the browser: the links are made absolute, so it opens that box's diagram in
// a new tab or window. If the SVG cannot be fetched (the page opened from a
// file: URL), the image and its link stay as they are.
(function () {
    "use strict";

    var XLINK = "http://www.w3.org/1999/xlink";
    var PX_PER_MM = 96 / 25.4;

    // "osc-14544.svg" -> "osc": faust -svg names a sub-diagram after its
    // definition, with a number to tell the instances apart.
    function levelName(url) {
        var base = url.split("/").pop().replace(/\.svg$/, "");
        return base === "process" ? "process" : base.replace(/-\d+$/, "") || base;
    }

    // "67.35mm" -> pixels, the size the <img> had.
    function toPx(length) {
        var m = /^([\d.]+)(mm|px)?$/.exec(length || "");
        if (!m) return null;
        return parseFloat(m[1]) * (m[2] === "mm" ? PX_PER_MM : 1);
    }

    function fetchSvg(url) {
        return fetch(url).then(function (r) {
            if (!r.ok) throw new Error(url + ": " + r.status);
            return r.text();
        }).then(function (text) {
            var svg = new DOMParser().parseFromString(text, "image/svg+xml").documentElement;
            if (svg.nodeName !== "svg") throw new Error(url + ": not an SVG");
            // The size of the diagram, scaled down by CSS when it does not fit.
            var vb = (svg.getAttribute("viewBox") || "").split(/[\s,]+/).map(parseFloat);
            var w = toPx(svg.getAttribute("width"));
            var h = toPx(svg.getAttribute("height"));
            if (w && h) {
                svg.setAttribute("width", w.toFixed(1));
                svg.setAttribute("height", h.toFixed(1));
            }
            if (vb.length === 4 && vb[2] > 0 && vb[3] > 0) svg.style.aspectRatio = vb[2] + " / " + vb[3];
            // The links, made absolute (they are relative to the SVG, not to the page).
            Array.prototype.forEach.call(svg.querySelectorAll("a"), function (a) {
                var href = a.getAttributeNS(XLINK, "href") || a.getAttribute("href");
                if (!href) return;
                var target = new URL(href, url).href;
                a.setAttributeNS(XLINK, "xlink:href", target);
                a.setAttribute("data-target", target);
            });
            return document.importNode(svg, true);
        });
    }

    function setup(box) {
        var start = new URL(box.getAttribute("data-src"), document.baseURI).href;
        var path = [];          // the levels shown, from the top one

        var bar = document.createElement("div");
        bar.className = "faust-diagram-bar";
        var crumbs = document.createElement("span");
        crumbs.className = "faust-diagram-crumbs";
        var open = document.createElement("a");
        open.className = "faust-diagram-open";
        open.target = "_blank";
        open.textContent = "open in a new tab ↗";
        bar.append(crumbs, open);
        var view = document.createElement("div");
        view.className = "faust-diagram-view";

        function render() {
            crumbs.replaceChildren();
            path.forEach(function (url, i) {
                if (i > 0) crumbs.append(" › ");
                if (i === path.length - 1) {
                    var here = document.createElement("strong");
                    here.textContent = levelName(url);
                    crumbs.append(here);
                } else {
                    var up = document.createElement("button");
                    up.type = "button";
                    up.textContent = levelName(url);
                    up.title = "back to this diagram";
                    up.addEventListener("click", function () { show(url); });
                    crumbs.append(up);
                }
            });
            open.href = path[path.length - 1];
            open.title = "open the diagram " + levelName(open.href) + " in a new tab, at its full size";
        }

        // Show the diagram at url: a level already on the path (going back up)
        // cuts the path there, any other one is added to it.
        function show(url) {
            return fetchSvg(url).then(function (svg) {
                view.replaceChildren(svg);
                var i = path.indexOf(url);
                if (i >= 0) path.length = i + 1; else path.push(url);
                render();
            });
        }

        view.addEventListener("click", function (e) {
            if (e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return;
            var a = e.target.closest("a[data-target]");
            if (!a || !view.contains(a)) return;
            e.preventDefault();
            show(a.getAttribute("data-target")).catch(function () {
                window.open(a.getAttribute("data-target"), "_blank");
            });
        });

        show(start).then(function () {
            box.replaceChildren(bar, view);
            box.classList.add("faust-diagram-live");
        }).catch(function () { /* keep the image and its link */ });
    }

    function init() {
        Array.prototype.forEach.call(document.querySelectorAll(".faust-diagram-box[data-src]"), setup);
    }

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
    else init();
})();
