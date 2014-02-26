$(document).ready(function() {
  player_hits();
  player_stays();
  dealer_hits();
});

function player_hits() {
  $(document).on('click', 'form#hit_button input', function() {
    $.ajax({
      type: 'POST',
      url: 'game/player/hit'
    }).done(function(message) {
      $('#game').replaceWith(message)
    });
    return false;
  });
}

function player_stays() {
  $(document).on('click', 'form#stay_button input', function() {
    $.ajax({
      type: 'POST',
      url: 'game/player/stay'
    }).done(function(message) {
      $('#game').replaceWith(message)
    });
    return false;
  });
}

function dealer_hits() {
  $(document).on('click', 'form#dealer_hit_button input', function() {
    $.ajax({
      type: 'POST',
      url: 'game/dealer/hit'
    }).done(function(message) {
      $('#game').replaceWith(message)
    });
    return false;
  });
}