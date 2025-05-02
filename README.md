# Categorização da base de dados de Despesas de Candidatos de 2004 a 2024.

29 de abril de 2025
## Escopo

A base de dados de despesas de candidatos do TSE, compiladas pelo CEPESP, possui as seguintes variáveis:
- DESCRICAO_DESPESA
- DETALHE_DESPESA
- DESCRICAO_ORIGEM_DESPESA

As três variáveis buscam detalhar e descrever  os gastos de campanha de um candidato a cargo eletivo, durante as campanhas eleitorais. No entanto, os dados apresentam os seguintes problemas:
- Não existem categorizações dos gastos.
- Não há padronização dos detalhamentos entre as eleições.
- Há um total de mais 29 milhões de registros de despesas na base toda.
- Ao unificarmos as três variáveis identificamos mais de 6 milhões de registros diferentes.

## Objetivo

- Categorizar os dados da base de despesas a partir de um conjunto menor e mais preciso de categorias com o uso de rede neural;
## Tarefa 1: Criação de Rótulos Manuais

Reduzimos as 52 categorias únicas de DS_TIPO_BEM_CANDIDATO para todas as eleições entre 2006 e 2022 em 6 categorias principais:

- Imóveis e Propriedade
- Investimentos Financeiros
- Outros Bens e Direitos
- Participações Societárias e Créditos
- Veículos
- Nenhum bem a declarar

Esta recategorização foi feita de forma manual e ad hoc. No link abaixo encontra-se a planilha com o match entre as 52 categorias originais e as 6 categorias sugeridas:

https://docs.google.com/spreadsheets/d/1wHH4bp9nV9YcfwpUAGbruavY4E5ddYd4m6QgDySVYEI/edit?usp=sharing

## Tarefa 2: Categorização da base com Rede Neural

Após a recategorização da base entre as seis categorias sugeridas na Tarefa 1, treinamos um modelo de **rede neural** com **aprendizado supervisionado** para classificar os dados da variável **DS_BEM_CANDIDATO**.

Utilizamos o modelo BERTimbau, um modelo BERT pré-treinado em língua portuguesa, contendo 24 camadas e 335 milhões de parâmetros. O modelo passou por fine-tuning utilizando dados supervisionados da base de bens de candidatos, com as seis categorias sugeridas na Tarefa 1 servindo como rótulos para o treinamento supervisionado.

Link do modelo: https://huggingface.co/neuralmind/bert-base-portuguese-cased

## Resultados

A classificação dos dados atingiu um alto índice de acurácia. Em uma validação manual com uma amostra de 900 observações (100 amostras para cada eleição entre 2006 a 2022), tivemos uma taxa de acerto de 99,3%. 

Quando comparamos o resultado obtido com o modelo BERT com os labels, a acurácia cai para 95,3%. Isso se deve ao fato de que existem erros na própria classificação do TSE e por algumas classificações confusas entre o que é considerado "Investimento Financeiro" e "Participações Societárias e Créditos". 

Os resultados da análise na amostra podem ser encontrados em: 

https://docs.google.com/spreadsheets/d/1A5ryn0lpfv_wI_2uSFN8WWpuabEPbbBzi7LkEYjcMX4/edit?usp=sharing

## Arquivos

- **output/bd02_2006_2022_final_bert_class.parquet** - base final com as classificações preditas pela rede neural BERT para todas as eleições;
- **modelo\mod02_bert_final** - Modelo BERTimbau com os parâmetros finais;
- **BERT - Categorizacao.ipynb** - arquivo jupyter com os códigos para aplicação do modelo BERTimbau para categorização da coluna;
- **BERT - Treino Colab.ipynb** - arquivo jupyter com os códigos de treinamento no Google Colab do modelo BERTimbau;
- **BERT - Treino.ipynb** - arquivo jupyter com os códigos de treinamento fora do Google Colab do modelo BERTimbau;
- **scriptA30_ML_Bens.R** - script com a preparação e limpeza dos dados para treino da rede neural. Aplicação também uma modelo de classificação com regressão logística multinomial que não foi usada no arquivo final. Salvamento do arquivo final; **output/bd02_2006_2022_final_bert_class.parquet** com a classificação BERTimbau.
- **classificacao_manual/primeira_categorizacao.xlsx** - planilha com a reclassificação das 54 categorias do TSE;
- **validacao_manual/amostra_bens_candidatos.xlsx** - planilha com a validação manual de uma amostra com 900 observações aleatórias do arquivo **output/bd02_2006_2022_final_bert_class.parquet**;
- **documentos/NLP com Deep Learning.pptx** - apresentação sobre Deep Learning, Transformers e o estado da arte em tarefas NLP.







