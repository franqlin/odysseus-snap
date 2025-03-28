
# Função para abrir um formulário no yad e obter os valores
abrir_formulario() {
    
    
  
        
        # Verifica se já existe um registro com id 1
        registro_existente=$(sqlite3 $pasta/reportdata-db.db "SELECT COUNT(*) FROM report WHERE id=1;")
        
        if [ "$registro_existente" -gt 0 ]; then
            # Carrega os dados do registro com id 1
            alterar_registro=$(sqlite3 $pasta/reportdata-db.db "SELECT referencia, solicitacao, registro FROM report WHERE id=1;")
            referencia=$(echo "$alterar_registro" | awk -F '|' '{print $1}')
            solicitacao=$(echo "$alterar_registro" | awk -F '|' '{print $2}')
            registro=$(echo "$alterar_registro" | awk -F '|' '{print $3}')
            
            # Abre o formulário para editar os dados
                        yad --form --title="Editar Registro" --height=400 --width=500 --field="Referência" --field="Solicitação" --field="Registro" --center --button="Salvar:0" --button="Cancelar:1" \
                            -- "$referencia" "$solicitacao" "$registro" | {
                            read -r referencia solicitacao registro
                            
                            echo " Antes Formulário enviado:"
                            echo "Referência: $referencia"
                            echo "Solicitação: $solicitacao"
                            echo "Registro: $registro"
                            
                            referencia=$(echo "$referencia" | tr -d '|')
                            solicitacao=$(echo "$solicitacao" | tr -d '|')
                            registro=$(echo "$registro" | tr -d '|')
                            
                            echo "Dados alterados:"
                            echo "Referência: $referencia"
                            echo "Solicitação: $solicitacao"
                            echo "Registro: $registro"

                            alterar_dados_tabela_report_data "$referencia" "$solicitacao" "$registro"
                            gravar_log "edit_report" "Registro alterado: $referencia, $solicitacao, $registro" 
            }
        else
            # Salva os dados no banco de dados
                        formulario=$(yad --form --title="Formulário de Registro" --height=400 --width=500 --field="Referência" --field="Solicitação" --field="Registro" --center)
                           if [ $? -eq 0 ]; then
                            referencia=$(echo "$formulario" | awk -F '|' '{print $1}')
                            solicitacao=$(echo "$formulario" | awk -F '|' '{print $2}')
                            registro=$(echo "$formulario" | awk -F '|' '{print $3}')
                            
                            referencia=$(echo "$referencia" | tr -d '|')
                            solicitacao=$(echo "$solicitacao" | tr -d '|')
                            registro=$(echo "$registro" | tr -d '|')

                            echo "Dados inseridos:"
                            echo "Referência: $referencia"
                            echo "Solicitação: $solicitacao"
                            echo "Registro: $registro"
                            
                            salvar_dados_tabela_report_data "$referencia" "$solicitacao" "$registro"
                            gravar_log "add_report" "Registro adicionado: $referencia, $solicitacao, $registro"
             fi
        fi
   
    
}

alterar_dados_tabela_report_data() {
    local referencia="$1"
    local solicitacao="$2"
    local registro="$3"
    
    # Comando SQL para alterar os dados na tabela report-data
    sqlite3 $pasta/reportdata-db.db <<EOF
UPDATE "report" SET referencia='$referencia', solicitacao='$solicitacao', registro='$registro' WHERE id=1;      
EOF
}
# Função para salvar os dados na tabela report-data
salvar_dados_tabela_report_data() {
    local referencia="$1"
    local solicitacao="$2"
    local registro="$3"
    
    # Comando SQL para inserir os dados na tabela report-data
    sqlite3 $pasta/reportdata-db.db <<EOF

INSERT INTO "report" (referencia, solicitacao, registro)
VALUES ('$referencia', '$solicitacao', '$registro');
EOF
}   