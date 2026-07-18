library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(readr)
library(ggplot2)
library(forcats)

# 1. DONNÉES -------------------------------------------------

arbres_data <- readr::read_csv(
  "outputs/arbres_nettoyes.csv",
  show_col_types = FALSE
) |>
  dplyr::mutate(
    date_releve = as.Date(date_releve),
    annee_releve = format(date_releve, "%Y"),

    classe_dhp = cut(
      dhp_cm,
      breaks = c(-Inf, 10, 30, 60, Inf),
      labels = c(
        "Moins de 10 cm",
        "10 à 29 cm",
        "30 à 59 cm",
        "60 cm et plus"
      ),
      right = FALSE
    ),

    anomalie = (
      is.na(espece_latin) |
      is.na(dhp_cm) |
      dhp_cm > 120 |
      is.na(x) |
      is.na(y)
    )
  )

arbres_sf <- sf::st_read(
  "outputs/arbres_outremont.gpkg",
  layer = "arbres",
  quiet = TRUE
)

arbres_sf <- sf::st_transform(arbres_sf, 4326)

genres <- sort(unique(na.omit(arbres_data$genre)))
rues <- sort(unique(na.omit(arbres_data$rue)))
annees <- sort(unique(na.omit(arbres_data$annee_releve)))


# 2. INTERFACE ------------------------------------------------

ui <- shiny::fluidPage(

  shiny::titlePanel(
    "Tableau de bord — Patrimoine arboré d’Outremont"
  ),

  shiny::sidebarLayout(

    shiny::sidebarPanel(

      shiny::selectInput(
        "genre",
        "Genre",
        choices = c("Tous", genres)
      ),

      shiny::selectInput(
        "classe_dhp",
        "Classe de DHP",
        choices = c(
          "Toutes",
          levels(arbres_data$classe_dhp)
        )
      ),

      shiny::selectizeInput(
        "rue",
        "Rue",
        choices = c("Toutes", rues)
      ),

      shiny::selectInput(
        "annee",
        "Année du relevé",
        choices = c("Toutes", annees)
      ),

      shiny::actionButton(
        "reset",
        "Réinitialiser"
      )
    ),

    shiny::mainPanel(

      shiny::fluidRow(
        shiny::column(3, shiny::h4("Arbres"), shiny::textOutput("kpi_total")),
        shiny::column(3, shiny::h4("Espèces"), shiny::textOutput("kpi_especes")),
        shiny::column(3, shiny::h4("DHP moyen"), shiny::textOutput("kpi_dhp")),
        shiny::column(3, shiny::h4("Anomalies"), shiny::textOutput("kpi_anomalies"))
      ),

      shiny::hr(),

      shiny::fluidRow(
        shiny::column(
          6,
          shiny::plotOutput("graph_genres")
        ),

        shiny::column(
          6,
          shiny::plotOutput("graph_dhp")
        )
      ),

      shiny::plotOutput("graph_classes"),

      shiny::h3("Carte interactive"),

      leaflet::leafletOutput(
        "carte",
        height = 600
      )
    )
  )
)


# 3. SERVEUR --------------------------------------------------

server <- function(input, output, session) {

  donnees_filtrees <- shiny::reactive({

    donnees <- arbres_data

    if (input$genre != "Tous") {
      donnees <- donnees |>
        dplyr::filter(genre == input$genre)
    }

    if (input$classe_dhp != "Toutes") {
      donnees <- donnees |>
        dplyr::filter(
          as.character(classe_dhp) == input$classe_dhp
        )
    }

    if (input$rue != "Toutes") {
      donnees <- donnees |>
        dplyr::filter(rue == input$rue)
    }

    if (input$annee != "Toutes") {
      donnees <- donnees |>
        dplyr::filter(annee_releve == input$annee)
    }

    donnees
  })


  donnees_spatiales <- shiny::reactive({

    ids <- donnees_filtrees()$id_arbre

    arbres_sf |>
      dplyr::filter(id_arbre %in% ids)
  })


  shiny::observeEvent(input$reset, {

    shiny::updateSelectInput(
      session,
      "genre",
      selected = "Tous"
    )

    shiny::updateSelectInput(
      session,
      "classe_dhp",
      selected = "Toutes"
    )

    shiny::updateSelectizeInput(
      session,
      "rue",
      selected = "Toutes"
    )

    shiny::updateSelectInput(
      session,
      "annee",
      selected = "Toutes"
    )
  })


  output$kpi_total <- shiny::renderText({
    nrow(donnees_filtrees())
  })


  output$kpi_especes <- shiny::renderText({
    dplyr::n_distinct(
      donnees_filtrees()$espece_latin,
      na.rm = TRUE
    )
  })


  output$kpi_dhp <- shiny::renderText({

    valeur <- mean(
      donnees_filtrees()$dhp_cm,
      na.rm = TRUE
    )

    paste0(round(valeur, 1), " cm")
  })


  output$kpi_anomalies <- shiny::renderText({

    sum(
      donnees_filtrees()$anomalie,
      na.rm = TRUE
    )
  })


  output$graph_genres <- shiny::renderPlot({

    donnees_filtrees() |>
      dplyr::filter(!is.na(genre)) |>
      dplyr::count(genre, sort = TRUE) |>
      dplyr::slice_head(n = 10) |>
      dplyr::mutate(
        genre = forcats::fct_reorder(genre, n)
      ) |>
      ggplot2::ggplot(
        ggplot2::aes(x = n, y = genre)
      ) +
      ggplot2::geom_col() +
      ggplot2::labs(
        title = "Dix principaux genres",
        x = "Nombre d’arbres",
        y = NULL
      ) +
      ggplot2::theme_minimal()
  })


  output$graph_dhp <- shiny::renderPlot({

    donnees_filtrees() |>
      dplyr::filter(
        !is.na(espece_latin),
        !is.na(dhp_cm)
      ) |>
      dplyr::group_by(espece_latin) |>
      dplyr::summarise(
        nb = dplyr::n(),
        dhp_moyen = mean(dhp_cm),
        .groups = "drop"
      ) |>
      dplyr::filter(nb >= 20) |>
      dplyr::slice_max(dhp_moyen, n = 10) |>
      dplyr::mutate(
        espece_latin =
          forcats::fct_reorder(
            espece_latin,
            dhp_moyen
          )
      ) |>
      ggplot2::ggplot(
        ggplot2::aes(
          x = dhp_moyen,
          y = espece_latin
        )
      ) +
      ggplot2::geom_col() +
      ggplot2::labs(
        title = "DHP moyen par espèce",
        subtitle = "Minimum de 20 arbres",
        x = "DHP moyen (cm)",
        y = NULL
      ) +
      ggplot2::theme_minimal()
  })


  output$graph_classes <- shiny::renderPlot({

    donnees_filtrees() |>
      dplyr::filter(!is.na(classe_dhp)) |>
      dplyr::count(classe_dhp) |>
      ggplot2::ggplot(
        ggplot2::aes(
          x = classe_dhp,
          y = n
        )
      ) +
      ggplot2::geom_col() +
      ggplot2::labs(
        title = "Répartition par classe de DHP",
        x = NULL,
        y = "Nombre d’arbres"
      ) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(
          angle = 25,
          hjust = 1
        )
      )
  })


  output$carte <- leaflet::renderLeaflet({

    donnees <- donnees_spatiales()

    leaflet::leaflet(donnees) |>
      leaflet::addTiles() |>
      leaflet::addCircleMarkers(
        radius = 4,
        stroke = FALSE,
        fillOpacity = 0.7,
        clusterOptions =
          leaflet::markerClusterOptions(),

        popup = ~paste0(
          "<b>Espèce :</b> ",
          espece_latin,
          "<br><b>Genre :</b> ",
          genre,
          "<br><b>DHP :</b> ",
          dhp_cm,
          " cm",
          "<br><b>Rue :</b> ",
          rue,
          "<br><b>Date :</b> ",
          date_releve
        )
      )
  })
}


shiny::shinyApp(
  ui = ui,
  server = server
)