<%

function formAdminResourceBookings
  usrAccessLevel = usrAccessAdminBookings
  formContainerCssClass = "resourceBookingsFormContainer"
  formContainerTitleCssClass = "resourceBookingsFormContainerTitle"
  formTitle = "Reservas"
  forms = array("formResourceBookings")
  childFormIds = "formResourceBookings"
end function

dim formResourceBookingsQueryTypeNames
formResourceBookingsQueryTypeNames = array("Todas las reservas", "Reservas con resultado pendiente", "Reservas no utilizadas")

dim formResourceBookingsQueryTypeSearchConditions
formResourceBookingsQueryTypeSearchConditions = array("", "dbo.RESULTADO_RESERVA(ID) = 'Pendiente'", "ID_RESULTADO=20")

dim formResourceBookingsQuerySearchFieldNames
formResourceBookingsQuerySearchFieldNames = array("Por Nombre")

dim formResourceBookingsQuerySearchFields
formResourceBookingsQuerySearchFields = array("NOMBRE")

dim formResourceBookingsQueryLimitNames
formResourceBookingsQueryLimitNames = array("hasta 100 ítems", "hasta 1000 ítems", "Todo")

dim formResourceBookingsQueryLimitClauses
formResourceBookingsQueryLimitClauses = array("TOP 100", "TOP 1000", "")

function formResourceBookingsBeforeUpdate
  formResourceBookingsBeforeUpdate = true
  if not inserting then exit function

  dim neighborId: neighborId = fieldNewValues(getFieldIndex("ID_VECINO"))
  dim resourceId: resourceId = fieldNewValues(getFieldIndex("ID_RECURSO"))
  dim bookingDate: bookingDate = stripDatePrefix(fieldNewValues(getFieldIndex("FECHA")))
  dim turnStart: turnStart = fieldNewValues(getFieldIndex("INICIO"))
  dim turnDuration: turnDuration = fieldNewValues(getFieldIndex("DURACION"))
  if not isNumeric(turnStart) then
    formResourceBookingsBeforeUpdate = reportError("El comienzo indicado no es válido.")
  end if
  turnStart = cInt(turnStart)
  if turnStart <= 0 or turnStart > 24 * 60 then
    formResourceBookingsBeforeUpdate = reportError("El comienzo indicado no es válido.")
    exit function
  end if
  if not isNumeric(turnDuration) then
    formResourceBookingsBeforeUpdate = reportError("La duración indicada no es válida.")
    exit function
  end if
  turnDuration = cInt(turnDuration)
  if turnDuration <= 0 or turnDuration > 24 * 60 then
    formResourceBookingsBeforeUpdate = reportError("La duración indicada no es válida.")
    exit function
  end if
  dbGetData("SELECT dbo.NOMBRE_RECURSO_RESERVA(" & resourceId & ")")
  dim resourceName: resourceName = rs(0)
  dbReleaseData
  if isNull(resourceName) then
    formResourceBookingsBeforeUpdate = reportError("El recurso indicado no es válido.")
    exit function
  end if
  if resourceId = clubHouseBookingResourceId and len(fieldNewValues(getFieldIndex("OBSERVACIONES"))) = 0 then
    formResourceBookingsBeforeUpdate = reportError("Para el recurso seleccionado se requiere que indique los Detalles.")
    exit function
  end if
  dim ok
  dbGetData("SELECT dbo.TURNO_RESERVA_VALIDO(" & resourceId & ", " & turnStart & ", " & turnDuration & ")")
  ok = rs(0)
  dbReleaseData
  if not ok then
    formResourceBookingsBeforeUpdate = reportError(resourceName & ": el turno indicado no es válido.")
    exit function
  end if
  dbGetData("SELECT CAST(CASE WHEN dbo.FECHA_INICIO_TURNO(" & sqlValue(fieldNewValues(getFieldIndex("FECHA"))) & ", " & _
    turnStart + turnDuration & ") > GETDATE() THEN 1 ELSE 0 END AS BIT)")
  ok = rs(0)
  dbReleaseData
  if not ok then
    formResourceBookingsBeforeUpdate = reportError("No está permitido cargar turnos que ya han finalizado.")
    exit function
  end if
  dbGetData("SELECT dbo.TURNO_RESERVA_DISPONIBLE(" & resourceId & ", " & sqlValue(fieldNewValues(getFieldIndex("FECHA"))) & ", " & _
    turnStart & ", " & turnDuration & ")")
  ok = rs(0)
  dbReleaseData
  if not ok then
    if isNull(neighborId) then
      formResourceBookingsBeforeUpdate = reportError(resourceName & ": no se puede bloquear para la fecha, comienzo y duración indicadas.")
    else
      formResourceBookingsBeforeUpdate = reportError(resourceName & ": no hay disponibilidad para el turno indicado.")
    end if
    exit function
  end if
end function

function formResourceBookingsAfterUpdate
  formResourceBookingsAfterUpdate = true
  if not inserting then exit function
  dim nro: nro = fieldNewValues(getFieldIndex("ID_RECURSO"))
  if nro < 100 then exit function
    
  dim rec: rec = ""
  if nro=100  then  
    rec = "Quincho"
  else
    rec = "House" 
  end if
  dim neighborId: neighborId = fieldNewValues(getFieldIndex("ID_VECINO"))
  dbGetData("SELECT NOMBRE, UNIDAD, EMAIL FROM VECINOS WHERE ID=" & neighborId)
  dim neighborName: neighborName = rs("NOMBRE")
  dim neighborUnit: neighborUnit = rs("UNIDAD")
  dim neighborMail: neighborMail = rs("EMAIL")
  dbReleaseData
  dim bookingDate: bookingDate = stripDatePrefix(fieldNewValues(getFieldIndex("FECHA")))
  dim turnStart: turnStart = fieldNewValues(getFieldIndex("INICIO"))
  dim turnDuration: turnDuration = fieldNewValues(getFieldIndex("DURACION"))
  dim details: details = fieldNewValues(getFieldIndex("OBSERVACIONES"))
  dbGetData("SELECT dbo.NOMBRE_TURNO(" & turnStart & ", " & turnDuration & ")")
  dim turnName: turnName = rs(0)
  dbReleaseData
  dim message
  message = "<p>Estimada familia " & neighborName & ":<br></p>" & _
    "<p>Queda CONFIRMADA su reserva de "&rec&" para el día "&systemDateStr(bookingDate)&". siendo el valor del Bono por uso de " & details&". " &_ 
"Acercamos las <a href=" & dQuotes("http://vecinosdetipas.com.ar/contenidos/Condiciones.pdf") & ">condiciones</a> de uso  para que las lea, complete y 72 hs antes del evento lo entregue firmado a la Guardia junto con la lista de invitados.</p>"&_
    "<table border=1>" & _
    "<tr><td>Unidad/Lote:</td><td>" & neighborUnit & "</td></tr>" & _
    "<tr><td>Familia:</td><td>" & neighborName & "</td></tr>" & _
    "<tr><td>Fecha del evento:</td><td>" & systemDateStr(bookingDate) & "</td></tr>" & _
    "<tr><td>Turno:</td><td>" & turnName & "</td></tr>" & _
    "<tr><td>Detalles:</td><td>" & details & "</td></tr>" & _
    "</table>"&_
   "<p> Muchas Gracias</p><p>Equipo de Vecinos de las Tipas</p>"
  sendCDOMail "Familia " & neighborName, neighborMail, "Unidad " & neighborUnit & " - Familia " & neighborName & " - Confirmación de Reserva del "&rec, message, "Las tipas - Reservas "&rec, "reservas@vecinosdetipas.com"
  JSONAddMessage("Se ha enviado un e-mail de notificación al vecino.")
end function

function formResourceBookingsBeforeDelete
  formResourceBookingsBeforeDelete = true
  getCurrentValues
end function

function formResourceBookingsAfterDelete
  formResourceBookingsAfterDelete = true

  if fieldCurrentValues(getFieldIndex("ID_RECURSO")) <> clubHouseBookingResourceId then exit function

  dim neighborId: neighborId = fieldCurrentValues(getFieldIndex("ID_VECINO"))
  dbGetData("SELECT NOMBRE, UNIDAD, EMAIL FROM VECINOS WHERE ID=" & neighborId)
  dim neighborName: neighborName = rs("NOMBRE")
  dim neighborUnit: neighborUnit = rs("UNIDAD")
  dim neighborMail: neighborMail = rs("EMAIL")
  dbReleaseData
  dim bookingDate: bookingDate = fieldCurrentValues(getFieldIndex("FECHA"))
  dim turnStart: turnStart = fieldCurrentValues(getFieldIndex("INICIO"))
  dim turnDuration: turnDuration = fieldCurrentValues(getFieldIndex("DURACION"))
  dim details: details = fieldCurrentValues(getFieldIndex("OBSERVACIONES"))
  dbGetData("SELECT dbo.NOMBRE_TURNO(" & turnStart & ", " & turnDuration & ")")
  dim turnName: turnName = rs(0)
  dbReleaseData
  dim message
  message = "<p>Estimada familia " & neighborName & ":<br></p>" & _
    "<p>Su reserva del Club House ha sido cancelada.</p>" & _
    "<p>Por cualquier duda o inconveniente mandar un mail a " & _
      "<a href=" & dQuotes("mailto:reservas@vecinosdetipas.com") & ">reservas@vecinosdetipas.com</a>.</p>" & _
    "<table border=1>" & _
    "<tr><td>Unidad/Lote:</td><td>" & neighborUnit & "</td></tr>" & _
    "<tr><td>Familia:</td><td>" & neighborName & "</td></tr>" & _
    "<tr><td>Fecha del evento:</td><td>" & systemDateStr(bookingDate) & "</td></tr>" & _
    "<tr><td>Turno:</td><td>" & turnName & "</td></tr>" & _
    "<tr><td>Detalles:</td><td>" & details & "</td></tr>" & _
    "</table>"
  sendCDOMail "Familia " & neighborName, neighborMail, "Unidad " & neighborUnit & " - Familia " & neighborName & " - Cancelación de Reserva del Club House", _
    message, "Las tipas - Reservas Club House", "reservas@vecinosdetipas.com"
  JSONAddMessage("Se ha enviado un e-mail de notificación al vecino.")
end function

function renderFormResourceBookingsRecordView
  if isNull(fieldCurrentValues(getFieldIndex("ID_VECINO"))) then
    recordViewFieldRenderFuncs(getFieldIndex("ID_RESULTADO")) = "renderRecordViewHiddenField"
    recordViewFieldRenderFuncs(getFieldIndex("dbo.RESULTADO_RESERVA(ID)")) = "renderRecordViewLiteralField"
  else
    recordViewReadOnlyFields(getFieldIndex("ID_RESULTADO")) = isNull(fieldCurrentValues(getFieldIndex("dbo.RESULTADO_RESERVA(ID)"))) and _
      isNull(fieldCurrentValues(getFieldIndex("ID_RESULTADO")))
  end if
  renderStandardRecordView
end function

function jBookingStartOptions(resourceId)
  if isNull(resourceId) then
    JSONAddStr "bookingTurnOptions", "[]"
  else
    dim b: b = dbConnect
    dbGetData("SELECT ID, NOMBRE FROM RESERVAS_TURNOS(" & resourceId & ") ORDER BY ID")
    JSONAddArray "bookingStartOptions", rs.getRows, array("id", "name")
    dbReleaseData
    if b then dbDisconnect
  end if
  JSONSend
end function

function jBookingDurationOptions(neighborId, resourceId, bookingStart)
  if isNull(resourceId) or isNull(bookingStart) then
    JSONAddStr "bookingDurationOptions", "[]"
  elseif isNull(neighborId) then
    dbGetData("SELECT ID, NOMBRE FROM dbo.RESERVAS_DURACIONES_BLOQUEOS(" & resourceId & ") ORDER BY ID")
    JSONAddArray "bookingDurationOptions", rs.getRows, array("id", "name")
    dbReleaseData
  else
    dbGetData("SELECT ID, NOMBRE FROM dbo.RESERVAS_DURACIONES(" & resourceId & ") WHERE INICIO=" & bookingStart & " ORDER BY ID")
    JSONAddArray "bookingDurationOptions", rs.getRows, array("id", "name")
    dbReleaseData
  end if
  JSONSend
end function

function formResourceBookings
  usrAccessLevel = usrAccessAdminBookings
  formTitle = ""
  formTable = "RESERVAS"
  
  formRecordViewRenderFunc = "renderFormResourceBookingsRecordView"
  formBeforeUpdateFunc = "formResourceBookingsBeforeUpdate"
  formAfterUpdateFunc = "formResourceBookingsAfterUpdate"
  formBeforeDeleteFunc = "formResourceBookingsBeforeDelete"
  'formAfterDeleteFunc = "formResourceBookingsAfterDelete"

  formGridViewRowCount = 25
  formGridColumns = array("FECHA", "dbo.NOMBRE_TURNO(INICIO, DURACION)", "dbo.NOMBRE_RECURSO_RESERVA(ID_RECURSO)", _
    "OBSERVACIONES", "dbo.UNIDAD_VECINO(ID_VECINO)", "dbo.NOMBRE_VECINO(ID_VECINO)", "dbo.RESULTADO_RESERVA(ID)", _
    "CASE WHEN ID_VECINO IS NULL THEN 'freezed' ELSE CASE WHEN dbo.RESULTADO_RESERVA(ID) = 'Pendiente' THEN 'hot' ELSE '' END END")
  formGridColumnLabels = array("Fecha", "Turno", "Recurso", "Detalles", "Unidad", "Vecino", "Resultado", "")
  formGridColumnTypes = array(formGridColumnDate, formGridColumnGeneralCenter, formGridColumnGeneralCenter, formGridColumnGeneral, _
    formGridColumnGeneralCenter,formGridColumnGeneral, formGridColumnGeneralCenter, formGridColumnHidden)
  formGridRowCssClassColumn = uBound(formGridColumns)
  formGridColumnWidths = array(55, 80, 110, 110, 50, 110, 90, 0)
  gridViewOrderBy = "1 DESC, 2, 3"
  gridViewReordering = false

  recordViewFieldLeftPos = 90
  recordViewEditboxWidth = 190
  recordViewIdFieldIsIdentity = true

  recordViewFields = array("ID", "FECHA", "ID_VECINO", "ID_RECURSO", "INICIO", "DURACION", "OBSERVACIONES", "ID_RESULTADO", "dbo.RESULTADO_RESERVA(ID)")
  recordViewDBFields = array(true, true, true, true, true, true, true, true, true)
  recordViewReadOnlyFields = array(true, not nullRecord, not nullRecord, not nullRecord, not nullRecord, not nullRecord, not nullRecord, nullRecord, true)
  recordViewFieldLabels = array("", "Fecha", "Vecino", "Recurso", "Comienzo", "Duración", "Detalles", "Resultado", "Resultado")
  recordViewFieldDefaults = array(null, date, null, null, null, null, null, null, null)
  recordViewNullableFields = array(true, false, true, false, false, false, true, false, true)
  recordViewFieldRenderFuncs = array("renderRecordViewIdentityField", "renderRecordViewDateField", _
    "renderRecordViewLookupField(" & dQuotes("VECINOS,NOMBRE,,neighborFieldChanged,ID_RECURSO") & ")", _
    "renderRecordViewLookupField(" & dQuotes("RESERVAS_RECURSOS,ID,,bookingResourceFieldChanged,INICIO") & ")", _
    "renderRecordViewLookupField(" & dQuotes("dbo.RESERVAS_TURNOS(dbo.ID_RECURSO_RESERVA(" & recordId & ")),ID,,bookingStartFieldChanged,DURACION") & ")", _
    "renderRecordViewLookupField(" & dQuotes("dbo.DURACION_RESERVA(" & recordId & "),ID") & ")", "renderRecordViewLiteralField", _
    "renderRecordViewLookupField(" & dQuotes("RESERVAS_RESULTADOS,ID") & ")", "renderRecordViewHiddenField")

  dim i, j
  dbGetData("SELECT COUNT(*) AS QTY FROM RESERVAS_RECURSOS")
  i = rs("QTY")
  dbReleaseData
  j = uBound(formResourceBookingsQueryTypeNames)
  if i > 0 then
    redim preserve formResourceBookingsQueryTypeNames(i + j)
    redim preserve formResourceBookingsQueryTypeSearchConditions(i + j)
    dbGetData("SELECT * FROM RESERVAS_RECURSOS ORDER BY ID")
    i = j + 1
    do while not rs.EOF
      formResourceBookingsQueryTypeNames(i) = rs("NOMBRE")
      formResourceBookingsQueryTypeSearchConditions(i) = "ID_RECURSO=" & rs("ID")
      rs.moveNext
      i = i + 1
    loop
    dbReleaseData
  end if
end function

%>
