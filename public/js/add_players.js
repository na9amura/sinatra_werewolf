function set_count(){
	$(".div_player").remove();
	var count = $('#count').val();
	for (var i = 0; i < count; i++) {
		var div_player = $("<div/>").attr("id", "player" + i).addClass("div_player");
		div_player.append($("<label/>").text("参加者" + (i + 1) ));
		div_player.append($("<input/>").attr("id", "name" + i).attr("name", "name" + i).attr("type", "text").addClass("txt_player"));
		$('#players').append(div_player);
	}
}

function post_players() {
	var param = [];
	$.each($(".div_player"), function() {
		param[param.length] = ($(this).children(".txt_player").val());
	});
	console.log(param);
	$.post("/chair/add/players/", {"players" :param}, function() {});
}
