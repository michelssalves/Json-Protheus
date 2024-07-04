#INCLUDE "protheus.CH"

User Function ExportPV()

    Local cFilPed		:= "01"
    Local cNumPed		:= "000011"
	Local cQuery		:= ""
	Local cAliasTop		:= ""
	Local oJson			:= Nil
	Local oJsonIt		:= Nil
	Local cJson			:= ""
	Local cControle		:= ""
	Local lPrim			:= .T.

	Default cFilPed := xFilial("SC5")
	Default cNumPed	:= ""

	cQuery := "SELECT " + CRLF
	cQuery += "	SC5.C5_NUM " + CRLF
	cQuery += "	, SC5.C5_EMISSAO " + CRLF
	cQuery += "	, SC5.C5_TPFRETE " + CRLF
	cQuery += "	, SC5.C5_FRETE " + CRLF
	cQuery += "	, SC5.C5_CONDPAG " + CRLF
	cQuery += "	, ( " + CRLF
	cQuery += "		SELECT SUM(C6T.C6_VALOR)  " + CRLF
	cQuery += "		FROM " + RetSQLName("SC6") + " C6T " + CRLF
	cQuery += "		WHERE " + CRLF
	cQuery += "		C6T.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "		AND C6T.C6_FILIAL = SC5.C5_FILIAL " + CRLF
	cQuery += "		AND C6T.C6_NUM = SC5.C5_NUM) VTOTAL " + CRLF
	cQuery += "	, SC6.C6_ITEM " + CRLF
	cQuery += "	, SC6.C6_PRODUTO " + CRLF
	cQuery += "	, SC6.C6_PRCVEN " + CRLF
	cQuery += "	, SC6.C6_QTDVEN " + CRLF
	cQuery += "	, SC6.C6_VALOR " + CRLF
	cQuery += "FROM " + RetSQLName("SC5") + " SC5 " + CRLF
	cQuery += "	INNER JOIN " + RetSQLName("SC6") + " SC6 " + CRLF
	cQuery += "		ON SC6.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "		AND SC6.C6_FILIAL = SC5.C5_FILIAL " + CRLF
	cQuery += "		AND SC6.C6_NUM = SC5.C5_NUM " + CRLF
	cQuery += "WHERE " + CRLF
	cQuery += "SC5.D_E_L_E_T_ = ' ' " + CRLF
	cQuery += "AND SC5.C5_FILIAL = '" + cFilPed + "' " + CRLF
	If !Empty(cNumPed)
		cQuery += "AND SC5.C5_NUM = '" + cNumPed + "' " + CRLF
	EndIf

	cAliasTop := MPSysOpenQuery(cQuery)

	If ! (cAliasTop)->(EOF())

		While ! (cAliasTop)->(EOF())
			If ! (cAliasTop)->C5_NUM == cControle
				If lPrim
					oJson := JsonObject():New()
					oJson["pedido"]		:= (cAliasTop)->C5_NUM
					oJson["emissao"]	:= DToC(SToD((cAliasTop)->C5_EMISSAO))
					oJson["tpfrete"] 	:= (cAliasTop)->C5_TPFRETE
					oJson["frete"]		:= If((cAliasTop)->C5_TPFRETE == "F","FOB","CIF")
					oJson["condpag"]	:= (cAliasTop)->C5_CONDPAG
					oJson["vtotal"]		:= (cAliasTop)->VTOTAL
					oJson["itens"]		:= {}
					lPrim := .F.
					cControle := (cAliasTop)->C5_NUM
				Else
					//dispara o json para a api do cliente
					cJson := oJson:toJson()
					Alert("Enviando json para a API do cliente...")
				
					oJson := JsonObject():New()
					oJson["pedido"]		:= (cAliasTop)->C5_NUM
					oJson["emissao"]	:= DToC(SToD((cAliasTop)->C5_EMISSAO))
					oJson["tpfrete"] 	:= (cAliasTop)->C5_TPFRETE
					oJson["frete"]		:= (cAliasTop)->C5_FRETE
					oJson["condpag"]	:= (cAliasTop)->C5_CONDPAG
					oJson["vtotal"]		:= (cAliasTop)->VTOTAL
					oJson["itens"]		:= {}
					cControle := (cAliasTop)->C5_NUM
				EndIf
			EndIf

			oJsonIt := JsonObject():New()
			oJsonIt["item"]			:= (cAliasTop)->C6_ITEM
			oJsonIt["produto"]		:= (cAliasTop)->C6_PRODUTO
			oJsonIt["quantidade"]	:= (cAliasTop)->C6_QTDVEN
			oJsonIt["preco"]		:= (cAliasTop)->C6_PRCVEN
			oJsonIt["vitem"]		:= (cAliasTop)->C6_VALOR
			AAdd(oJson["itens"], oJsonIt)
			()->(DbSkip())
		EndDo

		(cAliasTop)->(DbCloseArea())
		//dispara o json para a api do cliente
		cJson := oJson:toJson()
		Alert("Enviando json para a API do cliente...")

	EndIf

Return
