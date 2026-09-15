# Desde la raíz del repositorio:
# install.packages("scholar")
# source("R/scholar_pubs.R")
# scholar_pubs("mdktyS4AAAAJ")
# Scholar no identifica de forma fiable el tipo de publicación: revisar la lista
# para trasladar libros, pósters u otros materiales a su sección correspondiente.
scholar_pubs <- function(id, file = "Publications.qmd",
                         approved_titles = "data/article-titles.txt") {
  if (!requireNamespace("scholar", quietly = TRUE)) {
    stop('Instala el paquete con install.packages("scholar").')
  }
  if (length(id) != 1L || is.na(id) || !grepl("^[A-Za-z0-9_-]+$", id)) {
    stop("Indica un identificador válido de Google Scholar.")
  }
  original <- readLines(file, encoding = "UTF-8", warn = FALSE)
  start <- which(original == "<!-- scholar:start -->")
  end <- which(original == "<!-- scholar:end -->")
  if (length(start) != 1L || length(end) != 1L || start >= end) {
    stop("Faltan los marcadores scholar:start y scholar:end, o son incorrectos.")
  }
  publications <- scholar::get_publications(id, flush = TRUE)
  if (!is.data.frame(publications) || nrow(publications) == 0L ||
      !all(c("title", "author", "year", "journal", "pubid") %in% names(publications))) {
    stop("No se obtuvo una lista válida; se conserva el contenido existente.")
  }
  normalize_title <- function(x) {
    x[is.na(x)] <- ""
    x <- iconv(enc2utf8(x), to = "ASCII//TRANSLIT", sub = "")
    gsub("[^a-z0-9]", "", tolower(x))
  }
  approved <- normalize_title(readLines(approved_titles, encoding = "UTF-8"))
  excluded <- normalize_title(readLines("data/excluded-titles.txt", encoding = "UTF-8"))
  journals <- normalize_title(readLines("data/article-journals.txt", encoding = "UTF-8"))
  titles <- normalize_title(publications$title)
  venues <- normalize_title(publications$journal)
  # Scholar mezcla revista, volumen y páginas en el mismo campo.
  known_journal <- vapply(venues, function(venue) {
    any(vapply(journals, function(journal) {
      if (!nzchar(journal) || !startsWith(venue, journal)) return(FALSE)
      suffix <- substring(venue, nchar(journal) + 1L)
      !nzchar(suffix) || grepl("^[0-9]", suffix)
    }, logical(1)))
  }, logical(1))
  blocked <- titles %in% excluded
  accepted <- !blocked & (titles %in% approved | known_journal)
  pending <- publications[!accepted & !blocked, , drop = FALSE]
  publications <- publications[accepted & !duplicated(titles), , drop = FALSE]
  # Una respuesta incompleta nunca debe vaciar o recortar la web.
  existing_count <- sum(startsWith(original[seq.int(start, end)], "- "))
  if (nrow(publications) < existing_count || nrow(publications) == 0L) {
    stop("La descarga reduciría la lista existente; se conserva la última versión.")
  }
  write.csv(pending, "data/scholar-pending.csv", row.names = FALSE, fileEncoding = "UTF-8")
  if (nrow(pending)) warning(nrow(pending), " referencias nuevas pendientes de clasificación.")
  publications <- publications[order(-suppressWarnings(as.numeric(publications$year)),
                                   publications$title, na.last = TRUE), ]
  escape <- function(x) {
    if (length(x) == 0L || is.na(x)) return("")
    x <- gsub("[\r\n]+", " ", as.character(x))
    for (ch in c("&", "<", ">", "*", "_", "[", "]")) {
      x <- gsub(ch, switch(ch, "&" = "&amp;", "<" = "&lt;", ">" = "&gt;",
                          "*" = "&#42;", "_" = "&#95;", "[" = "&#91;", "]" = "&#93;"),
                x, fixed = TRUE)
    }
    x
  }
  entries <- vapply(seq_len(nrow(publications)), function(i) {
    p <- publications[i, ]
    url <- paste0("https://scholar.google.com/citations?view_op=view_citation&user=",
                  id, "&citation_for_view=", id, ":", p$pubid)
    year <- if (is.na(p$year) || !nzchar(as.character(p$year))) "s. f." else escape(p$year)
    journal <- escape(p$journal)
    paste0("- ", escape(p$author), " (", year, "). [", escape(p$title), "](", url, ").",
           if (nzchar(journal)) paste0(" *", journal, "*.") else "",
           if (grepl("biorxiv", journal, ignore.case = TRUE)) " **Preprint.**" else "")
  }, character(1))
  result <- c(original[seq_len(start)], "", paste(entries, collapse = "\n\n"), "",
              original[seq.int(end, length(original))])
  writeLines(enc2utf8(result), file, useBytes = TRUE)
  message(length(entries), " publicaciones actualizadas desde Google Scholar.")
  invisible(publications)
}
