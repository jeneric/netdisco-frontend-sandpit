// parameterised for the active tab - submits search form and injects
// HTML response into the tab pane, or an error/empty-results message
function do_search (event, tab) {
  var form = '#' + tab + '_form';
  var target = '#' + tab + '_pane';

  // stop form from submitting normally
  event.preventDefault();

  // copy current search string to other forms' input box
  $('form').find("input[name=q]").each( function() {
    $(this).val( $(form).find("input[name=q]").val() );
  });

  // hide or show sidebars depending on previous state,
  // and whether the sidebar contains any content (detected by TT)
  if (has_sidebar[tab] == 0) {
    $('.sidebar, #sidebar_toggle_img_out').hide();
    $('.content').css('margin-right', '10px !important');
  }
  else {
    if (sidebar_hidden) {
      $('#sidebar_toggle_img_out').show();
    }
    else {
      $('.content').css('margin-right', '220px !important');
      $('.sidebar').show();
    }
  }

  // get the form params
  var query = $(form).serialize();

  if (window.History && window.History.enabled) {
    is_from_history_plugin = 1;
    window.History.replaceState(
      {name: tab, fields: $(form).serializeArray()},
      'Netdisco '
        + path.charAt(0).toUpperCase() + path.slice(1) + ' - '
        + tab.charAt(0).toUpperCase() + tab.slice(1),
      uri_base + '/' + path + '?' + query
    );
    is_from_history_plugin = 0;
  }

  // in case of slow data load, let the user know
  $(target).html(
    '<div class="span2 alert">Waiting for results...</div>'
  );

  // submit the query and put results into the tab pane
  $(target).load( uri_base + '/ajax/content/' + path + '/' + tab + '?' + query,
    function(response, status, xhr) {
      if (status !== "success") {
        $(target).html(
          '<div class="span5 alert alert-error">' +
          'Search failed! Please contact your site administrator.</div>'
        );
        return;
      }
      if (response === "") {
        $(target).html(
          '<div class="span2 alert alert-info">No matching records.</div>'
        );
      }

      inner_view_processing(tab);
    }
  );
}

// keep track of which tabs have a sidebar, for when switching tab
var has_sidebar = {};
var sidebar_hidden = 0;

// the history.js plugin is great, but fires statechange at pushState
// so we have these semaphpores to help avoid messing the History.

// set true when faking a user click on a tab
var is_from_state_event = 0;
// set true when the history plugin does pushState - to prevent loop
var is_from_history_plugin = 0;

// on tab change, hide previous tab's search form and show new tab's
// search form. also trigger to load the content for the newly active tab.
function update_content(from, to) {
  $('#' + from + '_search').toggleClass('active');
  $('#' + to + '_search').toggleClass('active');

  var to_form = '#' + to + '_form';
  var from_form = '#' + from + '_form';

  if (window.History && window.History.enabled && is_from_state_event == 0) {
    is_from_history_plugin = 1;
    window.History.pushState(
      {name: to, fields: $(to_form).serializeArray()},
      'Netdisco '
        + path.charAt(0).toUpperCase() + path.slice(1) + ' - '
        + to.charAt(0).toUpperCase() + to.slice(1),
      uri_base + '/' + path + '?' + $(to_form).serialize()
    );
    is_from_history_plugin = 0;
  }

  $(to_form).trigger("submit");
}

// handler for ajax navigation
if (window.History && window.History.enabled) {
  var History = window.History;
  History.Adapter.bind(window, "statechange", function() {
    if (is_from_history_plugin == 0) {
      is_from_state_event = 1;
      var State = History.getState();
      // History.log(State.data.name, State.title, State.url);
      $('#'+ State.data.name + '_form').deserialize(State.data.fields);
      $('#'+ State.data.name + '_link').click();
      is_from_state_event = 0;
    }
  });
}

$(document).ready(function() {
  // activate tooltips
  $("[rel=tooltip]").tooltip({live: true});

  // bind submission to the navbar go icon
  $('#navsearchgo').click(function() {
    $('#navsearchgo').parent('form').submit();
  });

  // fix green background on search checkboxes
  // https://github.com/twitter/bootstrap/issues/742
  syncCheckBox = function() {
    $(this).parents('.add-on').toggleClass('active', $(this).is(':checked'));
  };
  $('.add-on :checkbox').each(syncCheckBox).click(syncCheckBox);

  // sidebar toggle - pinning
  $('#sidebar_pin_box').click(function() {
    $(this).toggleClass('sidebar_pin_box_pressed');
    $('.sidebar').toggleClass('sidebar_pinned');
  });
  // sidebar toggle - trigger in/out on image click()
  $('#sidebar_toggle_img_in').click(function() {
    $('.sidebar').toggle(
      function() {
        $('#sidebar_toggle_img_out').toggle();
        $('.content').animate({'margin-right': '10px !important'}, 50);
      }
    );
    sidebar_hidden = 1;
  });
  $('#sidebar_toggle_img_out').click(function() {
    $('#sidebar_toggle_img_out').toggle();
    $('.content').animate({'margin-right': '220px !important'}, 100,
      function() {
        $('.sidebar').toggle(200);
        if (! $('.sidebar').hasClass('sidebar_pinned')) {
            $(window).scrollTop(0);
        }
      }
    );
    sidebar_hidden = 0;
  });

  // could not get twitter bootstrap tabs to behave, so implemented this
  // but warning! will probably not work for dropdowns in tabs
  $('#search_results li').delegate('a', 'click', function(event) {
    event.preventDefault();
    var from_li = $('.nav-tabs').find('> .active').first();
    var to_li = $(this).parent('li')

    from_li.toggleClass('active');
    to_li.toggleClass('active');

    var from_id = from_li.find('a').attr('href');
    var to_id = $(this).attr('href');

    if (from_id == to_id) {
      return;
    }

    $(from_id).toggleClass('active');
    $(to_id).toggleClass('active');

    update_content(
      from_id.replace(/^#/,"").replace(/_pane$/,""),
      to_id.replace(/^#/,"").replace(/_pane$/,"")
    );
  });
});
