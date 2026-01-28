# plumber.R
library(plumber)

source("./make_letter.R")

#* Health check
#* @get /health
function() list(status = "ok")

#* Convert e-bill XML to PDF (for now: just accept XML and return pre-rendered PDF)
#* @post /convert_ebill
#* @serializer contentType list(type="application/pdf")
function(req, res) {

  # ---- read XML from HTTP body ----
  xml_text <- req$postBody  # character string (raw body)
  writeLines(xml_text,con="t_ebill.xml")
  # ---- for now: return pre-rendered PDF ----
  pdf_path<-render_pdf_bill("t_ebill.xml")
  file.remove("t_ebill.xml")
  res$setHeader("Content-Disposition", 'inline; filename="invoice.pdf"')
  readBin(pdf_path, what = "raw", n = file.info(pdf_path)$size)
}
