
// startup and termination

var appBaseWindowTitle = "Las tipas";
var startTime = null;
var childWindows = new Array();
var nextWindowStartupScript = "";

function init()
{
	ajaxGetText(server + "?verb=main", "", "",
    function() {
      document.body.innerHTML = ajaxResponseText;
      bodyResized();
      if (window.opener && window.opener.sessionId)
        getExistingSession(window.opener.sessionId);
      else
      {
        var d = new Date;
        startTime = d.getTime() + 1000;
        setTimeout(function() { start() }, 100);
      }
    }
  );
}

function start()
{
  var d = new Date;
  if (d.getTime() < startTime)
    setTimeout(function() { start() }, 100);
  else
    ajaxGetText(server + "?verb=adminLoginDialog", "dialogsPanel", "",
      function ()
      {
        document.getElementById("initialMessage").style.display = "none";
        showDialog();
        document.loginForm.usr.focus();
      }
    );
}

function activeChildWindows()
{
  for (var i = 0; i < childWindows.length; i++)
    if (childWindows[i] && childWindows[i].sessionId && childWindows[i].sessionId == sessionId)
      return(true);
  return(false);
}

function done()
{
  if ((window.opener && window.opener != window && window.opener.sessionId && window.opener.sessionId == sessionId) || activeChildWindows())
    return;
  logout();
}

function quit()
{
  if (((window.opener && window.opener != window && window.opener.sessionId && window.opener.sessionId == sessionId) || activeChildWindows()) &&
      !confirm("Tiene otras ventanas abiertas, las cuales no podrá usar si cierra la sesión.\n\n¿Desea cerrarla de todos modos?"))
    return;
  logout();
  window.location.reload();
}

// succsessful login ==========================================================

function loginOK()
{
  document.getElementById("usrNameLabel").innerHTML = usrName;
  document.getElementById("usrName").style.visibility = "visible";
  document.getElementById("menuBtn").style.display = "block";
  if (window.opener)
  {
    var s = "";
    try
    {
      s = window.opener.nextWindowStartupScript;
      if (s)
      {
        window.opener.nextWindowStartupScript = "";
        eval(s);
      }
      else
        showMenu();
    }
    catch (err) 
    {
      showMenu();
    }
  }
  else
    showMenu();
  document.getElementById("mainPanel").style.visibility = "visible";
  if (window.opener && window.opener.sessionId && window.opener.sessionId == sessionId)
    window.opener.childWindows[window.opener.childWindows.length] = window;
}

// forms loading ==============================================================

var refreshCurrentForm = false;

function load(menuElement, formContainerId)
{
  if (!formContainerId) return;
  if (refreshCurrentForm || !isFormLoaded(formContainerId))
	{
    hideMenu();
    ajaxAbort();
    loadFormContainer(formContainerId, "mainPanel");
    refreshCurrentForm = false;
  }
}

var menuHidden = true;

function menuBtnClick()
{
  if (menuHidden)
    showMenu();
  else
    hideMenu();
}

function hideMenu()
{
  if (!menuHidden)
  {
    document.getElementById("menuBackgnd").style.display = "none";
    menuHidden = true;
  }
}

function showMenu()
{
  if (menuHidden)
  {
    document.getElementById("menuBackgnd").style.display = "block";
    menuHidden = false;
  }
}

function bodyResized()
{
  var main = document.getElementById("main");
  if (main)
  {
    if (document.body.clientWidth > main.offsetWidth)
      main.style.left = Math.round((document.body.clientWidth - main.offsetWidth) / 2) + "px";
    else
      main.style.left = "0px";
    if (document.body.clientHeight > main.offsetHeight)
      main.style.top = Math.round((document.body.clientHeight - main.offsetHeight) / 2) + "px";
    else
      main.style.top = "0px";
    main.style.visibility = "visible";
  }
}

function openNewWindow()
{
  document.newWindowForm.action = window.location.href;
  document.newWindowForm.sessionId.value = sessionId;
  document.newWindowForm.submit();
}

function comboBoxAppendOption(combobox, text, value)
{
  var elOptNew = document.createElement('option');
  elOptNew.text = text;
  elOptNew.value = value;
  try {
    combobox.add(elOptNew, null); // standards compliant; doesn't work in IE
  }
  catch(e) {
    combobox.add(elOptNew); // IE only
  }
}

function openForm(recordId, formAdminId)
{
  nextWindowStartupScript = "firstFormRecordId = " + recordId + "; load(null, '" + formAdminId + "')";
  window.open(location.href);
}

function stopEvent(e)
{
  if (e.stopPropagation) 
    e.stopPropagation();
  else
    e.cancelBubble = true;
}

function cancelEvent(e)
{
  if (e.preventDefault)
    e.preventDefault();
  else
    e.returnValue = false;
}

// forms custom functions ============================================================================

var bookingResourceId = -1;

function neighborFieldChanged(formId, neighborComboBox, bookingResourcesComboBox)
{
  bookingResourcesComboBox.onchange();
}


function bookingResourceFieldChanged(formId, bookingResourcesComboBox, bookingStartComboBox)
{
  bookingResourceId = bookingResourcesComboBox.value;
  ajaxGetText(server + "?sessionId=" + sessionId + "&verb=jBookingStartOptions&bookingResourceId=" + bookingResourcesComboBox.value, "", "",
    function() {
      eval("var response = " + ajaxResponseText);
      bookingStartComboBox.length = 1;
      var newSelectedIndex = 0;
      for (i in response.bookingStartOptions)
        comboBoxAppendOption(bookingStartComboBox, response.bookingStartOptions[i].name, response.bookingStartOptions[i].id);
      bookingStartComboBox.selectedIndex = newSelectedIndex;
      bookingStartComboBox.onchange();
    }
  );
}

function bookingStartFieldChanged(formId, bookingStartComboBox, bookingDurationComboBox)
{
  var neighborId = document.formResourceBookings.field2NewValue.value;
  ajaxGetText(server + "?sessionId=" + sessionId + "&verb=jBookingDurationOptions&neighborId=" + neighborId + 
      "&bookingResourceId=" + bookingResourceId + "&bookingStart=" + bookingStartComboBox.value, "", "",
    function() {
      eval("var response = " + ajaxResponseText);
      bookingDurationComboBox.length = 1;
      var newSelectedIndex = 0;
      for (i in response.bookingDurationOptions)
        comboBoxAppendOption(bookingDurationComboBox, response.bookingDurationOptions[i].name, response.bookingDurationOptions[i].id);
      bookingDurationComboBox.selectedIndex = newSelectedIndex;
    }
  );
}



function formTimeLineNotifyNeighbors(recordId)
{
  ajaxGetText(server + "?sessionId=" + sessionId + "&verb=notifyNeighbors&recordId=" + recordId, "", "",
    function() {
      eval("var response = " + ajaxResponseText);
      if (response.message) alert(response.message);
    }
  );
}
function EnviarAlta(recordId)
{
  ajaxGetText(server + "?sessionId=" + sessionId + "&verb=EnviarAlta&recordId=" + recordId, "", "",
    function() {
      eval("var response = " + ajaxResponseText);
      if (response.message) alert(response.message);
    }
  );
}

