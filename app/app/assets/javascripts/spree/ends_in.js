$(document).ready(function() {
  setInterval(updateTimes, 1000);
});

function updateTimes() {
  var timeRemainings = $(".ends-in")
  if (timeRemainings.length > 0) {
    $.each(timeRemainings, updateTime);
  }
}

function updateTime(_, element) {
  var $element = $(element);
  var currentDatetime = new Date();
  var auctionEndDatetime = $element.data("auction-end-datetime");
  if (currentDatetime > auctionEndDatetime) {
    var pretext = $($element.siblings()[0]);
    pretext.addClass("green");
    pretext.html("Complete");
    $element.remove();
  } else {
    var countdownString = countdown(
      null,
      auctionEndDatetime,
      countdown.DAYS|countdown.HOURS|countdown.MINUTES|countdown.SECONDS,
      2
    ).toString();
  }
  element.innerHTML = countdownString;
}

