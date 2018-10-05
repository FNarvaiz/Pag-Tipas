
<%

const clubHouseBookingResourceId = 100

function renderDefaultReport
  %>
  <center>
  EN PREPARACIÓN...
  </center>
  <%
end function

function renderBookingListing
  dim bookingDate: bookingDate = fieldNewValues(getFieldIndex("FECHA"))
  dim resourceId: resourceId = fieldNewValues(getFieldIndex("ID_RECURSO"))
  dim s
  if isNull(resourceId) then 
    s = " AND R.ID_RECURSO < " & clubHouseBookingResourceId & " "
  else
    s = " AND R.ID_RECURSO = " & resourceId & " "
  end if
  if dbGetData("SELECT dbo.NOMBRE_RECURSO_RESERVA(ID_RECURSO) AS RECURSO, " & _
      "dbo.NOMBRE_TURNO(R.INICIO, R.DURACION) AS TURNO, " & _
      "V.UNIDAD, COALESCE(V.NOMBRE, '--BLOQUEADO--') AS NOMBRE " & _
      "FROM RESERVAS R LEFT JOIN VECINOS V ON V.ID = R.ID_VECINO " & _
      "WHERE R.FECHA=" & sqlDate(bookingDate) & s & _
      "GROUP BY R.ID_RECURSO, R.INICIO, R.DURACION, V.UNIDAD, V.NOMBRE " & _
      "ORDER BY R.ID_RECURSO, R.INICIO") then
    dim resourceName: resourceName = ""
    do while not rs.EOF
      if resourceName <> rs("RECURSO") then
        if len(resourceName) > 0 then
          %></tbody></table><br></center><%
          resourceName = rs("RECURSO")
        end if
        %>
        <center>
        <table class="reportLevel1" cellpadding="3" cellspacing="0" style="width: 40%">
        <thead>
        <tr><th colspan="3"><b><%= rs("RECURSO") %> - <%= renderReportFullDateColumn(systemDateFromNewValue(getFieldIndex("FECHA"))) %></b></tr>
        <tr>
          <th><b>Turno</b></th>
          <th><b>Lote</b></th>
          <th><b>Familia</b></th>
        </tr>
        </thead>
        <tbody>
        <%
      end if
      %>
      <tr>
        <td valign="top" align="center"><%= rs("TURNO") %></td>
        <td valign="top" align="center"><%= rs("UNIDAD") %></td>
        <td valign="top" align="center"><%= rs("NOMBRE") %></td>
      </tr>
      <%
      rs.moveNext
    loop
    if len(resourceName) > 0 then
      %></tbody></table><br></center><%
    end if
  else
    %><center></b><%
    if not isNull(resourceId) then 
      dbReleaseData
      dbGetData("SELECT dbo.NOMBRE_RECURSO_RESERVA(" & resourceId & ")")
      %><%= rs(0) %> - <%
    end if
    %>No hay reservas para el <%= renderReportFullDateColumn(systemDateFromNewValue(getFieldIndex("FECHA"))) %></b></center><%
  end if
  dbReleaseData
end function

%>