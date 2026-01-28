
library(stringr)
library(xml2)

extract_invoice_lines <- function(xml_file) {
  if (!requireNamespace("xml2", quietly = TRUE)) {
    stop("Package 'xml2' is required. Install it with: install.packages('xml2')", call. = FALSE)
  }
  
  # Read XML
  doc <- xml2::read_xml(xml_file)
  
  # UBL namespaces (as in typical XRechnung / UBL invoices)
  ns <- c(
    ubl = "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
    cac = "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
    cbc = "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  )
  
  lines <- xml2::xml_find_all(doc, ".//cac:InvoiceLine", ns = ns)
  
  get_text <- function(node, xpath) {
    x <- xml2::xml_find_first(node, xpath, ns = ns)
    if (length(x) == 0 || is.na(x)) return(NA_character_)
    txt <- xml2::xml_text(x)
    if (is.null(txt) || length(txt) == 0 || txt == "") NA_character_ else txt
  }
  
  out <- data.frame(
    ID = vapply(lines, get_text, character(1), xpath = "./cbc:ID"),
    Name = vapply(lines, get_text, character(1), xpath = "./cac:Item/cbc:Name"),
    InvoiceQuantity = suppressWarnings(as.numeric(vapply(lines, get_text, character(1), xpath = "./cbc:InvoicedQuantity"))),
    PriceAmount = suppressWarnings(as.numeric(vapply(lines, get_text, character(1), xpath = "./cac:Price/cbc:PriceAmount"))),
    LineExtensionAmount = suppressWarnings(as.numeric(vapply(lines, get_text, character(1), xpath = "./cbc:LineExtensionAmount"))),
    stringsAsFactors = FALSE
  )
  
  out
}


xml_leaf_list <- function(xml_input) {
  # read XML from file path OR string
  doc <- if (file.exists(xml_input)) {
    read_xml(xml_input)
  } else {
    read_xml(charToRaw(xml_input))
  }
  # all nodes
  nodes <- xml_find_all(doc, ".//*")
  # leaf nodes = nodes without element children
  leaves <- nodes[xml_length(nodes) == 0]
  # get qualified names including namespace prefix
  get_qname <- function(node) {
    ns <- xml_ns(doc)
    prefix <- xml_name(node)
    prefix
  }
  
  names_vec <- vapply(leaves, get_qname, character(1))
  values_vec <- xml_text(leaves, trim = TRUE)
  
  # remove empty values
  keep <- nzchar(values_vec)
  names_vec <- names_vec[keep]
  values_vec <- values_vec[keep]
  
  # make duplicate names unique
  names_vec <- make.unique(names_vec)
  l<-as.list(stats::setNames(values_vec, names_vec))
  l<-c(l,list(StreetName_abbrev="Ochensenwerder Landstr. 177"))
}



exchange_keys<-function(xml_taglist,df_invoice,base_file="prophet-analytics.tex"){
  #browser()
  tex_file<-readLines(base_file)
  xml_names<-names(xml_taglist)
  for (i in xml_names){
    tex_file<-str_replace_all(tex_file,paste0('<',i,'>'),xml_taglist[[i]])
  }
  
  tex_file<-build_table(tex_file,df_invoice)
  writeLines(tex_file,base_file)
}


build_table<-function(tex_file,df_invoice){
  #browser()
  table_rows<-lapply(1:nrow(df_invoice),function(x,df_invoice){
    t_row<-df_invoice[x,]
    paste0(t_row$ID, ' & ',
           t_row$Name,' & ',
           t_row$InvoiceQuantity,' & ',
           paste0('\\EURO{',
                  sprintf("%.2f",t_row$PriceAmount)%>%str_replace('\\.',','),
                  '}'),
           ' & ',
           paste0('\\EURO{',
             sprintf("%.2f",t_row$LineExtensionAmount)%>%str_replace('\\.',','),
             '}'),
           '\\\\')
  },df_invoice=df_invoice) %>% unlist()
  index<-str_which(tex_file,'<TableRows>')
  tex_file<-c(tex_file[1:(index-1)],
              table_rows,
              tex_file[(index+1):length(tex_file)]
  )
  
  return(tex_file)
  #print(table_rows)
}

prepare_builddir<-function(template_dir,build_dir){
  l_files<-dir(template_dir)
  for (i in l_files){
    file.copy(paste0(template_dir,'/',i),paste0(build_dir,'/',i))
  }
}

cleanup_builddir<-function(build_dir){
  l_files<-dir(build_dir)
  for (i in l_files){
    if(i!="prophet-analytics.pdf"){
      file.remove(paste0(build_dir,'/',i))
    }
  }
}


render_pdf_bill<-function(xml_input="ebill.xml"){
  browser()
  template_dir<-"./template/"
  #build_dir<-"./build/"
  build_dir<-tempdir()
  work_dir<-getwd()


  xml_taglist<-xml_leaf_list(xml_input)
  df_invoice<-extract_invoice_lines(xml_input)
  prepare_builddir(template_dir,build_dir)


  setwd(build_dir)
  exchange_keys(xml_taglist,df_invoice)
  system(paste0("pdflatex ",
    build_dir,"/prophet-analytics.tex")
    )
  

  setwd(work_dir)
  cleanup_builddir(build_dir)
  return(paste0(build_dir,"/prophet-analytics.pdf"))
}