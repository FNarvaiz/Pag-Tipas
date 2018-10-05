
var currentBrickContent = "";

function loadBrickContent(content, param)
{
  if (ajaxBusy()) return;
  if (currentBrickContent != content)
	{
    hideDataViewer();
    document.getElementById("dynPanel").innerHTML = "";
    currentBrickContent = content;
    brickListingDataType = param;
    ajaxLoadingSignalOn(loadingSignalId);
    ajaxGetText(server + "?lang=" + lang + "&sessionId=" + sessionId + "&content=" + content + "&projectId=" +
      brickProjectId + "&param=" + param, "", "",
      function() {
        if (!ajaxResponseText)
        {
          if (lang == "SP")
            alert("Su acceso ha caducado, debe ingresar nuevamente.");
          else
            alert("Your session has expired. Please, login again.");
          logout();
        }
        else
        {
          document.getElementById("dynPanel").innerHTML = ajaxResponseText;
          if (brickListingDataType)
            mainMenuOptionChanged(currentBrickContent + brickListingDataType + "MenuOption");
          else
            mainMenuOptionChanged(currentBrickContent + "MenuOption");
          var brickListing = document.getElementById("brickListing");
          if (brickListing && brickListing.scrollHeight <= brickListing.offsetHeight)
          {
            document.getElementById("brickListingUpArrow").style.visibility = "hidden";
            document.getElementById("brickListingDownArrow").style.visibility = "hidden";
          }
          var timeLine = document.getElementById("timeLine");
          if (timeLine)
            if (timeLine.scrollWidth <= timeLine.offsetWidth)
              document.getElementById("timeLineArrows").style.visibility = "hidden";
            else
              timeLine.scrollLeft = timeLine.scrollWidth - timeLine.offsetWidth;
          switch (currentBrickContent)
          {
            case "timeLine":
              timeLineColumnSelectedIdx = -1;
              timeLineDataTypeSelected = -1;
              eval(document.getElementById("javascriptCode").innerHTML);
              ajaxLoadingSignalOff();
              break;
            default:
              ajaxLoadingSignalOff();
              break;
          }
        }
      }
    );
  }
}


