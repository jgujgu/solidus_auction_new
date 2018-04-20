$(document).ready(function() {
  setInterval(updateCheckoutTimes, 1000);
});

function updateCheckoutTimes() {
  var checkoutRemainings = $(".checkout-in")
  if (checkoutRemainings.length > 0) {
    $.each(checkoutRemainings, updateCheckoutTime);
  }
}

function updateCheckoutTime(_, element) {
  var $element = $(element);
  var currentDatetime = new Date();
  var dateTime = $element.data("auction-checkout-deadline");
  if (currentDatetime > dateTime) {
    var pretext = $($element.siblings()[0]);
    pretext.addClass("green");
    pretext.html("Complete");
    $element.remove();
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
