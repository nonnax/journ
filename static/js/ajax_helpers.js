updater = function(id, url) {
	new Ajax.Updater(id, url, {
        method: 'get',
		insertion: Insertion.Bottom
    });
};
Event.observe(window, 'load', function(){  
	$('post-input').focus();  // always ready to take your input!
});

Event.observe(window, 'load', function(){
  new Ajax.Autocompleter('post-topics', 'auto-topics', '/auto', {
	  tokens:',', 
	  method:'get', 
	  frequency: 0, 
	  decay: 2 }
	  );
});