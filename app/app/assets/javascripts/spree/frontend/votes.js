var root;

Spree.ready(function () {
  $(document).ready(function() {
    root = getRootUrl();
    setInterval(updateVotes, 60000);
    var votes = $(".votes")
    votes.click(changeVote)
  });
})

function updateVotes() {
  var votes = $(".votes")
  if (votes.length > 0) {
    $.each(votes, updateVote);
  }
}

function updateVote(_, element) {
  var $element = $(element);
  var auctionId = $element.data('auction-id');
  var params = { auction_id: auctionId };

  Spree.ajax({
    url: root + "/vote_count/",
    data: params,
    success: function(data) {
      $element.children()[0].innerHTML = data["votes"];
    }
  });
}

function changeVote(e) {
  e.preventDefault();
  var $this = $(this);
  var userId = $this.data('user-id');
  if (userId) {
    var auctionId = $this.data('auction-id');
    var votedFor = $this.data('voted-for');
    var params = {auction_id: auctionId, user_id: userId };
    if (votedFor) {
      Spree.ajax({
        url: root + "/vote_down/",
        data: params,
        success: setVoteWidget.bind(this)
      });
    } else {
      Spree.ajax({
        url: root + "/vote_up/",
        data: params,
        success: setVoteWidget.bind(this)
      });
    }
  }
}

function setVoteWidget(data) {
  var votedFor = data["voted_for"];
  var $this = $(this);
  if (votedFor == 1) {
    setData($this, 'voted-for', true);
    $this.addClass("green");
    $this.children()[0].innerHTML = data["votes"];
  } else {
    setData($this, 'voted-for', false);
    $this.removeClass("green");
    $this.children()[0].innerHTML = data["votes"];
  }
}

function setData(element, key, data) {
  element.data(key, data);
  element.attr('data-' + key, data);
}

function getRootUrl() {
  var defaultPorts = {"http:":80,"https:":443};

  return window.location.protocol + "//" + window.location.hostname
  + (((window.location.port)
      && (window.location.port != defaultPorts[window.location.protocol]))
        ? (":"+window.location.port) : "");
}
