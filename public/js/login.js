function btnLogin_onclick(){
		$.post(
		'/entry/validate/',
		{
			name: $('#name').val()
			,password: $('#password').val()
		},
		login_onSuccess);
}

function login_onSuccess(result){
	var json = eval(result);
	if (json.result == 'error'){
		$.each(json.messages, function(i, message){
			$('#message').text(message)
		});
	} else if (json.result == 'success') {
		$('#login_form').submit();
	}
}