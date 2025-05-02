# Classificação Despesas de Candidatos
# Marco Antonio Faganello - marcofaga@gmail.com - http://github.com/marcofaga
# Data de início: 28 de abril de 2025
# Codificação: Banco em ASCII e Script em UTF-8
# Descrição do Script: Base e Análise

# AREA DO A4 na ABNT (com 5 cm de margens):
# Full page: 160x247mm em in 6.3x9.7 em px com 300 dpi 1890x2917
# Meia Página: 160X124mm / 6.3x4.9in / 1890x1470 (300 dpi)
# Áurea menor: 160x094mm / 6.3x3.7in / 1890x1110 (300 dpi)
# Áurea maior: 160X153mm / 6.3x6.0in / 1890X1800 (300 dpi)

# Tamanho de Gráfico Recomendado
# Menor: 2931 x 1566 (razão 1.871648)
# Médio: 2199 x 1890 (razão 1.163492)

# colorBrewer Divergente (4 cores): #e66101, #fdb863, #b2abd2, #5e3c99
# colorBrewer Sequencial (4 cores): #fef0d9, #fdcc8a, #fc8d59, #d7301f

# libraries ====================================================================

library(tidyverse)
library(beepr)
library(janitor)
library(arrow)
library(stringi)
library(tidymodels)
library(textrecipes)
library(tidytext)
library(googlesheets4)

# options=======================================================================
options(stringsAsFactors = F)
options(knitr.kable.NA = '-')
options(timeout=10000)

# functions=====================================================================
#apl <- list.files("../../../../R/functions/", full.names = T)
#lapply(apl, source)
#remove(apl)
stop()

# script =======================================================================

## base_despesas_2002_2024.parquet =============================================

# salvando arquivos rds do cepespdata em um parquet único

files <- list.files("raw/JoinFinal/", full.names = T, pattern = "parquet")

data <- tibble()

for(f in files) {
  
  dt <- read_parquet(f) |> mutate_all(as.character)
  data <- bind_rows(data, dt)
  
}

write_parquet(data, "raw/base_despesas_2002_2024.parquet")


## bd01_gastos_treino ==========================================================

### Rotulação Manual ===========================================================

df <- open_dataset("raw/base_despesas_2002_2024.parquet")

desp <- 
  df |>
  select(ID_CEPESP,
         VERSAO_CEPESP,
         ANO_ELEICAO,
         CPF_CANDIDATO,
         DATA_DESPESA,
         DATA_ELEICAO,
         DESC_SETOR_ECONOMICO_FORNECEDOR,
         DESC_SETOR_FORNECEDOR,
         DESCRICAO_CARGO,
         DESCRICAO_CNAE_FORNECEDOR,
         DESCRICAO_ELEICAO,
         DESCRICAO_DESPESA,
         DETALHE_DESPESA,
         DESCRICAO_ORIGEM_DESPESA,
         DS_TIPO_FORNECEDOR,
         NOME_MUNICIPIO_DESPESA,
         NUM_TURNO,
         NUMERO_CANDIDATO,
         ORIGEM_RECURSO,
         SIGLA_PARTIDO,
         SIGLA_UF,
         VALOR_DESPESA) |>
  collect() |>
  arrange(ANO_ELEICAO,
          SIGLA_UF,
          DESCRICAO_CARGO,
          NUMERO_CANDIDATO)

desp$descricao_despesa_arrumado <- tolower(desp$DESCRICAO_DESPESA)
desp$descricao_despesa_arrumado <- stri_trans_general(desp$descricao_despesa_arrumado, "Latin-ASCII")
desp$descricao_despesa_arrumado <- trimws(desp$descricao_despesa_arrumado)

desp$detalhe_arrumado <- tolower(desp$DETALHE_DESPESA)
desp$detalhe_arrumado <- stri_trans_general(desp$detalhe_arrumado, "Latin-ASCII")
desp$detalhe_arrumado <- trimws(desp$detalhe_arrumado)

desp$origem_arrumado <- tolower(desp$DESCRICAO_ORIGEM_DESPESA)
desp$origem_arrumado <- stri_trans_general(desp$origem_arrumado, "Latin-ASCII")
desp$origem_arrumado <- trimws(desp$origem_arrumado)

tipos <- desp |> select(descricao_despesa_arrumado, detalhe_arrumado, origem_arrumado) |> unique()
tipos <- tipos |> mutate(across(everything(), ~ifelse(. == "#ne", "", .)))
tipos$geral <- paste(tipos$descricao_despesa_arrumado, tipos$detalhe_arrumado, tipos$origem_arrumado, sep=" ")
tipos$geral <- trimws(tipos$geral)
tipos$geral <- gsub("[^[:alnum:]]", " ", tipos$geral)
tipos$geral <- trimws(tipos$geral)
tipos$geral <- gsub(" {2,}", " ", tipos$geral)

# Vamos usar uma técnica de active learning para rotular os dados
# Vamos começar com 100 amostras aleatórias.

set.seed(10)
amostra01 <- tipos |> select(geral) |> slice_sample(n = 100)
write.csv2(amostra01, "clipboard", row.names = F)

set.seed(15)
amostra02 <- tipos |> select(geral) |> slice_sample(n = 100)
write.csv2(amostra02, "clipboard", row.names = F)

set.seed(30)
amostra03 <- tipos |> select(geral) |> slice_sample(n = 5000)
write.csv2(amostra03, "clipboard-1500", row.names = F)

set.seed(50)
amostra04 <- tipos |> select(geral) |> slice_sample(n = 100)
write.csv2(amostra04, "clipboard-1500", row.names = F)

### Montagem da Base de Treino =================================================

plan <- read_sheet("1Uok10taufJvctD9as9rbo0aqU56gj4itVmpfed8mzqM")
names(plan) <- c("ds_gastos", "categoria")
plan$y <- as.numeric(as.factor(plan$categoria)) - 1
write_parquet(plan, "bases/bd01_gastos_treino.parquet")

apcats <- plan |> select(categoria, y) |> unique()
write_rds(apcats, "bases/categorias_labels_num.rds")

## bd01_gastos_apply ===========================================================

tipos2 <- tipos |> filter(!geral %in% plan$ds_gastos)
set.seed(60)
tipos2 <- tipos2 |> sample_n(1000)
tipos2 <- tipos2 |> select(geral)
tipos2$y <- NA
names(tipos2) <- c("ds_gastos", "y")
write_parquet(tipos2, "bases/bd01_gastos_apply.parquet")



## bd01_gastos_treino ===========================================================


## bd02_base_final =============================================================

files <- list.files("raw", full.names = T, pattern = "parquet")

df <- open_dataset(files)

bens <- 
  df |>
  collect()

bens$id <- c(1:nrow(bens))

bens$tipo_arrumado <- tolower(bens$DS_TIPO_BEM_CANDIDATO)
bens$tipo_arrumado <- stri_trans_general(bens$tipo_arrumado, "Latin-ASCII")
  
tipos <- 
  bens |>
  group_by(ANO_ELEICAO, tipo_arrumado) |>
  summarise(n = n()) |>
  filter(ANO_ELEICAO >= 2010)

categoria1 <- read_csv("raw/primeira_categorizacao.csv") |> clean_names()

bens$categoria_cepesp <- categoria1$classificacao_sugerida[match(bens$tipo_arrumado, categoria1$categorias_fornecidas)]
bens$categoria_cepesp[bens$ANO_ELEICAO == 2008] <- NA
bens$categoria_cepesp[bens$ANO_ELEICAO == 2006] <- NA

bens$DS_BEM_CANDIDATO_2 <- bens$DS_BEM_CANDIDATO
bens$DS_BEM_CANDIDATO_2[bens$DS_BEM_CANDIDATO_2 == "#NULO"] <- bens$DS_TIPO_BEM_CANDIDATO[bens$DS_BEM_CANDIDATO_2 == "#NULO"]
bens$DS_BEM_CANDIDATO_2 <- trimws(bens$DS_BEM_CANDIDATO_2)
bens$DS_BEM_CANDIDATO_2 <- gsub("\\s+", " ", bens$DS_BEM_CANDIDATO_2)

bens$y <- as.numeric(as.factor(bens$categoria_cepesp)) 
bens_final <- bens |> filter(!is.na(y))
bens_final$y <- bens_final$y - 1

bens_final <- bens_final |> select(id, DS_BEM_CANDIDATO_2)
bens_final <- clean_names(bens_final)

write_parquet(bens_final, "bases/bd02_final.parquet")

## A01. Regressão Logística Multinomial ========================================

# Carregar o dataset (supondo que o arquivo seja 'seu_arquivo.csv')
data <- 
  read_parquet("bases/bd01_benscand_treino.parquet") |>
  mutate(cat = as.factor(categoria_cepesp)) |>
  select(ds_bem_arrum, cat) #|>
  #sample_n(10000)

# transformações de texto na variável bens de candidato
bens$DS_BEM_ARRUM <- bens$DS_BEM_CANDIDATO
bens$DS_BEM_ARRUM[bens$DS_BEM_CANDIDATO == "#NULO"] <- bens$DS_TIPO_BEM_CANDIDATO[bens$DS_BEM_CANDIDATO == "#NULO"]
bens$DS_BEM_ARRUM <- gsub("[^[:alnum:] ]+", "", bens$DS_BEM_ARRUM)
bens$DS_BEM_ARRUM <- gsub("[0-9]", "", bens$DS_BEM_ARRUM)
bens$DS_BEM_ARRUM <- trimws(bens$DS_BEM_ARRUM)  
bens$DS_BEM_ARRUM[bens$DS_BEM_ARRUM == ""] <- bens$DS_TIPO_BEM_CANDIDATO[bens$DS_BEM_ARRUM == ""]
bens$DS_BEM_ARRUM <- gsub("[^[:alnum:] ]+", "", bens$DS_BEM_ARRUM)
bens$DS_BEM_ARRUM <- gsub("[0-9]", "", bens$DS_BEM_ARRUM)
bens$DS_BEM_ARRUM <- trimws(bens$DS_BEM_ARRUM)  
bens$DS_BEM_ARRUM <- tolower(bens$DS_BEM_ARRUM)
bens$DS_BEM_ARRUM <- stri_trans_general(bens$DS_BEM_ARRUM, "Latin-ASCII")


# Dividir os dados em treino (80%) e teste (20%), estratificando pela variável 'tipo'
set.seed(123)
data_split <- initial_split(data, prop = 0.8, strata = cat)
train_data <- training(data_split)
test_data  <- testing(data_split)

# Arrumando os acentos da stopwords
stop <- stopwords::stopwords("pt")
stop <- stri_trans_general(stop, "Latin-ASCII")


# Criar uma receita para o pré-processamento do texto
rec <- recipe(cat ~ ds_bem_arrum, data = train_data) %>%
  # Tokenizar o texto
  step_tokenize(ds_bem_arrum) %>%
  # Remover stopwords em português
  step_stopwords(ds_bem_arrum, custom_stopword_source = stop) %>%
  # Filtrar tokens menos frequentes para reduzir dimensionalidade
  step_tokenfilter(ds_bem_arrum, max_tokens = 500) %>%
  # Converter para uma representação TF-IDF
  step_tfidf(ds_bem_arrum)

# Visualizar dados da recei (usar com base de dados pequena)
#rec_prepped <- prep(rec)
#processed_data <- bake(rec_prepped, new_data = train_data)
#View(head(processed_data))

# Especificar o modelo de regressão logística multinomial com o engine 'nnet'
modelo <- multinom_reg() %>%
  set_engine("nnet", MaxNWts = 10000) %>%
  set_mode("classification")

# Criar um workflow que une a receita e o modelo
wf <- workflow() %>%
  add_recipe(rec) %>%
  add_model(modelo)

# Treinar o modelo com os dados de treino
fit_model <- wf %>% fit(data = train_data)

# Fazer previsões no conjunto de teste
predictions <- predict(fit_model, test_data) %>%
  bind_cols(test_data)

# Avaliar o desempenho utilizando métricas (por exemplo, acurácia)
metrics <- metrics(predictions, truth = cat, estimate = .pred_class)
print(metrics)


# Supondo que seu workflow treinado esteja na variável `modelo_treinado`
saveRDS(fit_model, "modelo/mod01_regressao_multinomial.rds")

## A02 - Base Final ============================================================

apx <- read_parquet("output/base_final_2006_2008.parquet")

apx1 <- read_parquet("output/base_testando.parquet")

apx$categoria_cepesp_bert <- apx1$categoria_cepesp[match(apx$y_pred, apx1$y)]

apx2 <- read_parquet("output/base_final_2010_2022.parquet")
apx2$categoria_cepesp_bert <- apx1$categoria_cepesp[match(apx2$y_pred, apx1$y)]

# colocando na base de bens

files <- list.files("raw", full.names = T, pattern = "parquet")

df <- open_dataset(files)

bens <- 
  df |>
  collect() |>
  arrange(ANO_ELEICAO)

bens$tipo_arrumado <- tolower(bens$DS_TIPO_BEM_CANDIDATO)
bens$tipo_arrumado <- stri_trans_general(bens$tipo_arrumado, "Latin-ASCII")

tipos <- 
  bens |>
  group_by(ANO_ELEICAO, tipo_arrumado) |>
  summarise(n = n()) |>
  filter(ANO_ELEICAO >= 2010)

categoria1 <- read_csv("raw/primeira_categorizacao.csv") |> clean_names()

bens$categoria_cepesp_manual <- categoria1$classificacao_sugerida[match(bens$tipo_arrumado, categoria1$categorias_fornecidas)]
bens$categoria_cepesp_manual[bens$ANO_ELEICAO == 2008] <- NA
bens$categoria_cepesp_manual[bens$ANO_ELEICAO == 2006] <- NA
bens$id <- c(1:nrow(bens))
bens$DS_BEM_CANDIDATO_CEPESP <- bens$DS_BEM_CANDIDATO
bens$DS_BEM_CANDIDATO_CEPESP[bens$DS_BEM_CANDIDATO_CEPESP == "#NULO"] <- bens$DS_TIPO_BEM_CANDIDATO[bens$DS_BEM_CANDIDATO_CEPESP == "#NULO"]
bens$DS_BEM_CANDIDATO_CEPESP <- trimws(bens$DS_BEM_CANDIDATO_CEPESP)
bens$DS_BEM_CANDIDATO_CEPESP <- gsub("\\s+", " ", bens$DS_BEM_CANDIDATO_CEPESP)

benscat_bert <- apx |> select(id, ds_bem_candidato_2, categoria_cepesp_bert)
apx2 <- apx2 |> select(-y_pred)
benscat_bert <- rbind(benscat_bert, apx2)

bens$categoria_cepesp_bert <- benscat_bert$categoria_cepesp_bert[match(bens$id, benscat_bert$id)]
bens$categoria_cepesp_bert[bens$DS_BEM_CANDIDATO_CEPESP == "NENHUM BEM A DECLARAR"] <- "Nenhum bem a declarar"

# mudando a categoria "Imóveis" para Imóvel ou Propriedade
bens$categoria_cepesp_bert[bens$categoria_cepesp_bert == "Imóveis"] <- "Imóvel ou Propriedade"
bens$categoria_cepesp_manual[bens$categoria_cepesp_manual == "Imóveis"] <- "Imóvel ou Propriedade"


# Pegando amostra de 100 aleatórias em cada ano para validação manual

set.seed(10)

amostra <- 
  bens |>
  select(id,
         ANO_ELEICAO,
         DS_BEM_CANDIDATO,
         DS_BEM_CANDIDATO_CEPESP,
         DS_TIPO_BEM_CANDIDATO,
         categoria_cepesp_manual,
         categoria_cepesp_bert) |>
  group_by(ANO_ELEICAO) |>
  sample_n(100)

amostra$DS_BEM_CANDIDATO <- gsub("\\s+", " ", amostra$DS_BEM_CANDIDATO)

write_csv2(amostra, "validacao_manual/amostra_bens_candidatos.csv", quote = "all")

write_parquet(bens, "output/bd02_2006_2022_final_bert_class.parquet")
