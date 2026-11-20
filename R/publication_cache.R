# La vista previa solo lee esta copia. Las consultas requieren una llamada explícita.
cache_valida <- function(x) {
  is.data.frame(x) && nrow(x) > 0L &&
    all(c("title", "author", "journal", "year", "pubid") %in% names(x)) &&
    !anyNA(x$title) && all(nzchar(trimws(x$title)))
}

leer_publicaciones <- function(file = "data/scholar-cache.csv") {
  x <- read.csv(file, stringsAsFactors = FALSE, check.names = FALSE,
                fileEncoding = "UTF-8", colClasses = "character")
  if (!cache_valida(x)) stop("La copia guardada de publicaciones no es válida.")
  x
}

actualizar_publicaciones <- function(id = "mdktyS4AAAAJ",
                                    file = "data/scholar-cache.csv",
                                    max_autores = 5L) {
  anterior <- leer_publicaciones(file)
  # Al primer aviso (incluido 429), aborta la consulta y conserva la copia.
  consultar <- function(expr) {
    tryCatch(
      withCallingHandlers(expr, warning = function(w) stop(conditionMessage(w))),
      error = function(e) {
        message("Consulta detenida: ", conditionMessage(e))
        NULL
      }
    )
  }
  nueva <- consultar(scholar::get_publications(id, flush = TRUE))
  if (!cache_valida(nueva) || nrow(nueva) < nrow(anterior)) {
    message("Se conserva la copia anterior: descarga inválida o incompleta.")
    return(invisible(FALSE))
  }

  # Reutiliza los autores ya recuperados, también tras la primera descarga.
  normalizar <- function(x) {
    gsub("[^[:alnum:]]", "", tolower(enc2utf8(x)))
  }
  coincidencia <- match(normalizar(nueva$title), normalizar(anterior$title))
  truncado <- function(x) is.na(x) | !nzchar(x) | grepl("\\.\\.\\.|…|\\bet al\\.|\\bothers\\b", x)
  for (i in which(!is.na(coincidencia))) {
    prev <- anterior$author[coincidencia[i]]
    if (truncado(nueva$author[i]) && !truncado(prev)) nueva$author[i] <- prev
  }

  # Limita las consultas adicionales; no vuelve a pedir autores ya completos.
  pendientes <- which(truncado(nueva$author) & !is.na(nueva$pubid) & nzchar(nueva$pubid))
  for (i in head(pendientes, max_autores)) {
    autores <- consultar(scholar::get_complete_authors(
      id, nueva$pubid[i], delay = 2, initials = FALSE
    ))
    if (is.null(autores)) break
    if (is.character(autores) && length(autores) == 1L && !truncado(autores)) {
      nueva$author[i] <- autores
    }
  }

  nueva <- nueva[order(nueva$title), c("title", "author", "journal", "year", "pubid")]
  temporal <- tempfile(pattern = "scholar-", tmpdir = dirname(file))
  on.exit(unlink(temporal), add = TRUE)
  write.csv(nueva, temporal, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  leer_publicaciones(temporal)
  if (!file.copy(temporal, file, overwrite = TRUE)) stop("No se pudo guardar la copia.")
  message("Copia actualizada: ", nrow(nueva), " publicaciones.")
  invisible(TRUE)
}
