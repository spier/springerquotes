// jQuery.noConflict();

jQuery(document).ready(function($){	
	// init the general form UI
    // $(document).uiforms()

	$("#search_terms").click(function() {
	  	if ($(this).val() == "Enter Your Search"){
			$(this).val("");
		}
	});
	// init the buttons more properly than done by .uiforms() above
	$("a.button").button();
	// $("a.button").addClass('uiforms-submit');
	// $("input:submit, input:reset, input:button").button();
	$(':submit').addClass('uiforms-submit');
	$(':input').addClass('uiforms-input ui-state-default ui-corner-all');
	$(':text').addClass('uiforms-text');
	
	// Dynamically add and remove classes
    $(':input').hover(function() {
       $(this).addClass('ui-state-hover');
    }, function() {
        $(this).removeClass('ui-state-hover');  
    });
    $(':input').focus(function() {
       $(this).addClass('ui-state-focus');   
    });
    $(':input').blur(function() {
       $(this).removeClass('ui-state-focus');   
    });
		
	// add rounded corners
	$('#container').addClass('ui-corner-all');	
	$('#credit').addClass('ui-corner-all');	
	
	$('.quote').addClass('ui-corner-all');	
	$('.result').addClass('ui-corner-all');	
	$('#highlighting_explanation').addClass('ui-corner-all');
	$('#about').addClass('ui-corner-all');
	$('#simple_explanation').addClass('ui-corner-all');
	$('#quotes_explanation').addClass('ui-corner-all');

	// add the highlight class to the results when hovering in/out
	$(".result").hover(function() {
	  	$(this).toggleClass("highlight");
	});
	
	// // add the highlight class to the results when hovering in/out
	// $("span").hover(function() {
	//   	$(this).toggleClass("blueBg");
	// })
	
	// // make an collapsible accordian out of the highlighting_explanation
	// $("#highlighting_explanation").accordion({
	// 	collapsible: true
	// });
	
	// when clicking anywhere on the result box, open the article in a new page
	// PROBLEM: when clicking on the link of the article itself, both events are triggered. possible workaround: don't make this open in a new page but instead change the URL of this page.
	$(".result").click(function() {
		window.location = $(this).children("a").attr("href");
	});
})
