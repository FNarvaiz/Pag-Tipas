<%

function formAdminNeighbors
  usrAccessLevel = usrAccessAdminNeighbors
  formContainerCssClass = "neighborsFormContainer"
  formContainerTitleCssClass = "neighborsFormContainerTitle"
  formTitle = "Vecinos"
  forms = array("formNeighbors", "formNeighborsActivity")
  childFormIds = "formNeighbors"
end function

dim formNeighborsQueryTypeNames
formNeighborsQueryTypeNames = array("Habilitados", "Deshabilitados", "Habilitados con permiso p/servicios", _
  "Habilitados sin permiso p/servicios", "Todos")

dim formNeighborsQueryTypeSearchConditions
formNeighborsQueryTypeSearchConditions = array("HABILITADO=1", "HABILITADO=0", "HABILITADO=1 AND PERMISO_SERVICIOS=1", _
  "HABILITADO=1 AND PERMISO_SERVICIOS=0", "")

dim formNeighborsQuerySearchFieldNames
formNeighborsQuerySearchFieldNames = array("Por Nombre")

dim formNeighborsQuerySearchFields
formNeighborsQuerySearchFields = array("UNIDAD + ' ' + NOMBRE")

function formNeighbors
  usrAccessLevel = usrAccessAdminNeighbors
  formTitle = ""
  formTable = "VECINOS"
  childFormIds = "formNeighborsActivity"
  
  formGridViewRowCount = 27
  formGridColumns = array("dbo.SPACE_PAD(UNIDAD, 15)", "NOMBRE")
  formGridColumnTypes = array(formGridColumnGeneralCenter, formGridColumnGeneral)
  formGridColumnLabels = array("Unidad", "Familia")
  formGridColumnWidths = array(70, 200)
  gridViewReordering = false
  gridViewOrderBy = "1"
  defaultQueryLimit = -1

  recordViewFieldLeftPos = 110
  recordViewEditboxWidth = 180

  recordViewIdFieldIsIdentity = true
  recordViewSeparators = array("Datos básicos", null, null, null, "Datos de acceso", null, null, null, "Notas","Notificar alta") 
  recordViewFields = array("ID", "UNIDAD", "NOMBRE", "TELEFONOS", "EMAIL", "CLAVE", "HABILITADO", "PERMISO_SERVICIOS", "NOTAS","NOTIFICAR")
  recordViewDBFields = array(true, true, true, true, true, true, true, true, true,false)
  recordViewReadOnlyFields = array(true, false, false, false, false, false, false, false, false,true)
  recordViewFieldLabels = array("Código", "Unidad/Lote", "Familia", "Teléfonos", "e-mail", "Contraseña", "Acceso habilitado", "Permiso p/servicios", "","")
  recordViewFieldDefaults = array(null, null, null, null, null, null, true, true, null,null)
  recordViewNullableFields = array(true, false, false, true, false, false, false, false, true,true)
  recordViewFieldRenderFuncs = array("renderRecordViewIdentityField", "renderRecordViewLiteralField", _
    "renderRecordViewNameField", "renderRecordViewLiteralField", "renderRecordViewLiteralField", _
    "renderRecordViewLiteralField", "renderRecordViewBooleanField", "renderRecordViewBooleanField", "renderRecordViewNotesField(10)","renderNotificarVecinoBtn")
end function

function formNeighborsActivity
  usrAccessLevel = usrAccessAdminNeighbors

  formTitle = ""
  formTable = "VECINOS_ACTIVIDADES"
  parentFormId = "formNeighbors"
  keyFieldName = "ID_VECINO"
  
  formGridViewRowCount = 30
  formGridColumns = array("FECHA", "ACTIVIDAD", "ACTIVIDAD_DETALLES")
  formGridColumnTypes = array(formGridColumnDateTime, formGridColumnGeneral, formGridColumnGeneral)
  formGridColumnLabels = array("Fecha", "Actividad", "Detalles")
  formGridColumnWidths = array(90, 110, 140)
  gridViewReordering = true
  gridViewOrderBy = "1 DESC"
  defaultQueryLimit = -1
  
  formRecordViewRenderFunc = null
end function
function renderNotificarVecinoBtn
  if nullRecord then exit function
  recordViewFieldTopPos = recordViewFieldTopPos + 4
  %>
  <input type="button" class="navButton" value="EnviarAlta"
    onclick="EnviarAlta(<%= recordId %>)"
    <%= renderBooleanAttr("disabled", recordViewDisabled or nullRecord) %>
    style="left: 10px; top: <%= recordViewFieldTopPos %>px; width: 120px"
  <%
  renderNotificarVecinoBtn = recordViewDefaultFieldHeight + 4
end function
function EnviarAlta
 if dbGetData("SELECT NOMBRE, UNIDAD, EMAIL,CLAVE FROM VECINOS WHERE ID=" & recordId) then
    dim mensaje : mensaje= "<h3>Bienvenido a la web de Vecinos de Tipas, le confirmamos el ALTA, su CONTRASEÑA PROVISORIA de acceso es " & rs("CLAVE").value & ",  sírvase ingresar en el sistema nuevamente y modifique su clave personal. "&_

"Le hemos asignado una contraseña provisoria la cual le sugerimos cambiar una vez que ingrese por primera vez.</h3>"&_
"<table border=1>" & _
    "<tr><td>Unidad/Lote:</td><td>" & rs("UNIDAD").value & "</td></tr>" & _
    "<tr><td>Familia:</td><td>" & rs("NOMBRE").value & "</td></tr>" & _
    "<tr><td>e-mail:</td><td>" & rs("EMAIL").value & "</td></tr>" & _
    "<tr><td>Contraseña:</td><td>" & rs("CLAVE").value & "</td></tr>" & _
    "</table><h2>Muchas Gracias"&_
"Equipo Vecinos de Las Tipas </h2>"

      dim result: result = sendCDOMail(rs("NOMBRE").value, rs("EMAIL").value,"Alta de las tipas",mensaje,"Equipo de las tipas",mainEmailAddress)
      if len(result) = 0 then
          JSONAddMessage("Se ha enviado un e-mail de alta al correo "&rs("EMAIL").value&", con copia a " & mainEmailAddress & ".")
      else
        JSONAddMessage("Se ha producido un error al enviar el e-mail (Error: " & result & ").")
      end if
    
  else
    JSONAddMessage("Error interno: No se pudo leer la base de datos.")
  end if
  dbReleaseData
  JSONSend
end function
%>
