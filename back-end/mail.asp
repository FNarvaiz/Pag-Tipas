<%@ LANGUAGE="VBSCRIPT" CODEPAGE="65001" %>
<% option explicit %>
<%
response.expires=-1
response.charSet = "utf-8"
session.codePage = 65001

%>
<!--#include file="forms/formsUtils.asp"-->
<!--#include file="forms/utils/db.asp"-->

<!--#include file="credits.asp"-->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="es">
<head>
<title>Brick Barrio Golf - Prueba de mail</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Content-Script-Type" content="text/javascript">
</head>
<body leftmargin="0" topmargin="0">
  <%
    dbConnect
    const mainEmailName = "Las tipas"
    const mainEmailAddress = "info@vecinosdetipas.com.ar"
    dim recordId: recordId = 589
    if dbGetData("SELECT NOMBRE, dbo.NOMBRE_CATEGORIA_LINEA_TIEMPO(ID_CATEGORIA) AS CATEGORIA, APROBADO, COALESCE(CONTENIDO_TEXTO, '') AS TEXTO, " & _
      "dbo.EMAILS_VECINOS() AS EMAILS, ARCHIVO_FILENAME, ARCHIVO_BINARYDATA " & _
      "FROM LINEA_TIEMPO WHERE ID=" & recordId) then
    if not rs("APROBADO") then
      %>"Para enviar una notificación por e-mail, el ítem seleccionado debe estar aprobado."<%
    else
      dim errCode
      errCode = sendGroupMail(mainEmailAddress, "clago@gbd.com.ar", rs("NOMBRE"), replace(rs("TEXTO"), vbLf, "<br>"), _
        rs("ARCHIVO_FILENAME"), rs.fields("ARCHIVO_BINARYDATA"))
      if errCode = 0 then
        %>"Se ha enviado un e-mail a todos los vecinos, con copia a " & mainEmailAddress & "."<%
      else
        %>"Se ha producido un error al intentar enviar el e-mail (Código=" & errCode & ")."<%
      end if
    end if
  else
    %>"Error interno: no se encontró el registro en el Archivo histórico (ID=" & recordId & ")."<%
  end if
  dbReleaseData
  dbDisconnect
  %>
</body>
</html>
