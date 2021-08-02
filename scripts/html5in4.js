/* Script to extend the HTML4 elements in the HTML to   *
 * use HTML5 element types and attributes when possible */
 
if (document.querySelectorAll && window.addEventListener) {
  window.addEventListener('load', function() {
    var input = document.createElement("input");
    input.setAttribute("type", "url");

    if (input.type === "text") {
      return;
    }

    var inputs = document.querySelectorAll('input[type=text][name=q],input[type=text][name=filter]');

    for (var i = inputs.length - 1; i >= 0; i--) {
      inputs[i].setAttribute("spellcheck", "false");
      inputs[i].setAttribute("autocorrect", "off");

      if (inputs[i].name == "q") {
        inputs[i].setAttribute("required", "true");
      }
    }
  });
}
