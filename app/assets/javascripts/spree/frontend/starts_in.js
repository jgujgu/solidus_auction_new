$(document).ready(function() {
  setInterval(updateStartTimes, 1000);
});

function updateStartTimes() {
  var timeRemainings = $(".starts-in")
  if (timeRemainings.length > 0) {
    $.each(timeRemainings, updateStartTime);
  }
}

function updateStartTime(_, element) {
  var $element = $(element);
  var currentDatetime = new Date();
  var dateTime = $element.data("auction-starting-datetime");
  if (currentDatetime > dateTime) {
    $element.removeClass("starts-in");
    $element.removeClass("green");
    $element.addClass("ends-in");
    $element.addClass("red");
    var pretext = $element.siblings()[0];
    pretext.innerHTML = "Ends in";
  } else {
    var countdownString = countdown(
      dateTime,
      null,
      countdown.DAYS|countdown.HOURS|countdown.MINUTES|countdown.SECONDS,
      2
    ).toString();
  }
  element.innerHTML = countdownString;
}
