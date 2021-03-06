print_mat = function(maf, genes, removeNonMutated = TRUE, colors = NULL,
                     bgCol = 'gray70', borderCol = 'white', fontSize = 1,
                     plot2 = FALSE, test = FALSE, clinicalFeatures = NULL,
                     additionalFeature = NULL, additionalFeaturePch = 20, additionalFeatureCol = "white", additionalFeatureCex = 0.9,
                     annotationDat = NULL, annotationColor = NULL,
                     sortByAnnotation = FALSE, showBarcodes = FALSE,
                     title = NULL, title_size = 1.2, barcode_size = 1, sepwd_samples = 0.1, sepwd_genes = 0.1){

  tsbs = levels(getSampleSummary(x = maf)[,Tumor_Sample_Barcode])
  genes = as.character(genes)

  om = createOncoMatrix(m = maf, g = genes)
  if(is.null(om)){
    #nsamps = as.numeric(maf@summary[ID %in% 'Samples', summary])
    nsamps = length(tsbs)
    oncoMatrix = matrix(data = "", nrow = length(genes), ncol = nsamps)
    numericMatrix = matrix(data = 0, nrow = length(genes), ncol = nsamps)
    colnames(oncoMatrix) = colnames(numericMatrix) = tsbs
    rownames(oncoMatrix) = rownames(numericMatrix) = genes

    om = list(numericMatrix = numericMatrix, oncoMatrix =oncoMatrix)
  }

  mat_origin = om$oncoMatrix
  numMat = om$numericMatrix

  genes.missing = genes[!genes %in% rownames(mat_origin)]
  genes.present = genes[genes %in% rownames(mat_origin)]

  if(length(genes.present) > 0){
    genes.missing.mat = t(matrix(data = '', ncol = ncol(numMat), nrow = length(genes.missing)))
    genes.missing.numat = t(matrix(data = 0, ncol = ncol(numMat), nrow = length(genes.missing)))
    colnames(genes.missing.mat) = genes.missing
    colnames(genes.missing.numat) = genes.missing
    mat_origin = rbind(mat_origin, t(genes.missing.mat))
    numMat = rbind(numMat, t(genes.missing.numat))
  }

  #remove nonmutated samples to improve visualization
  if(!removeNonMutated){
    tsb.include = matrix(data = 0, nrow = length(genes),
                         ncol = length(tsbs[!tsbs %in% colnames(numMat)]))
    tsb.include.char = matrix(data = '', nrow = length(genes),
                         ncol = length(tsbs[!tsbs %in% colnames(numMat)]))
    colnames(tsb.include) = colnames(tsb.include.char) = tsbs[!tsbs %in% colnames(numMat)]
    rownames(tsb.include) = rownames(tsb.include.char) = rownames(numMat)
    numMat = cbind(numMat, tsb.include)
    mat_origin = cbind(mat_origin, tsb.include.char)
  }

  numMat = numMat[genes, , drop = FALSE]
  mat_origin = mat_origin[genes, , drop = FALSE]

  #Parse annotations
  if(!is.null(clinicalFeatures)){
    if(is.null(annotationDat)){
      annotation = parse_annotation_dat(annotationDat = maf, clinicalFeatures = clinicalFeatures)
    }else{
      annotation = parse_annotation_dat(annotationDat = annotationDat, clinicalFeatures = clinicalFeatures)
    }

    if(sortByAnnotation){
      numMat = sortByAnnotation(numMat = numMat, maf = maf, anno = annotation)
    }
  }

  if(is.null(colors)){
    vc_col = get_vcColors()
  }else{
    vc_col = colors
  }
  vc_codes = om$vc #VC codes

  percent_alt = paste0(round((apply(numMat, 1, function(x) length(x[x != 0])) / length(tsbs)) * 100), "%")


  if(plot2){
    if(is.null(clinicalFeatures)){
      if(showBarcodes){
        par(mar = c(5, 1, 3, 3))
      }else{
        par(mar = c(1, 1, 3, 3))
      }
    }else{
      if(showBarcodes){
        par(mar = c(5, 1, 3, 5))
      }else{
        par(mar = c(1, 1, 3, 5))
      }
    }
  }else{
    if(is.null(clinicalFeatures)){
      if(showBarcodes){
        par(mar = c(5, 3, 3, 1))
      }else{
        par(mar = c(1, 3, 3, 1))
      }
    }else{
      if(showBarcodes){
        par(mar = c(5, 5, 3, 1))
      }else{
        par(mar = c(1, 5, 3, 1))
      }
    }
  }

  if(test){
    return(list(numMat, vc_col[om$vc]))
  }

  nm = t(apply(numMat, 2, rev))
  nm[nm == 0] = NA
  image(x = 1:nrow(nm), y = 1:ncol(nm), z = nm, axes = FALSE, xaxt="n", yaxt="n",
        xlab="", ylab="", col = "white") #col = "#FC8D62"
  #Plot for all variant classifications
  vc_codes_temp = vc_codes[!vc_codes %in% c('Amp', 'Del')]
  for(i in 2:length(names(vc_codes_temp))){
    vc_code = vc_codes_temp[i]
    col = vc_col[vc_code]
    nm = t(apply(numMat, 2, rev))
    nm[nm != names(vc_code)] = NA
    suppressWarnings(image(x = 1:nrow(nm), y = 1:ncol(nm), z = nm, axes = FALSE, xaxt="n", yaxt="n",
          xlab="", ylab="", col = col, add = TRUE))
  }

  #Add blanks
  nm = t(apply(numMat, 2, rev))
  nm[nm != 0] = NA
  image(x = 1:nrow(nm), y = 1:ncol(nm), z = nm, axes = FALSE, xaxt="n", yaxt="n", xlab="", ylab="", col = bgCol, add = TRUE)

  #Add CNVs if any
  mat_origin = mat_origin[rownames(numMat), colnames(numMat), drop = FALSE]
  mo = t(apply(mat_origin, 2, rev))

  ##Complex events (mutated as well as CN altered)
  complex_events = unique(grep(pattern = ";", x = mo, value = TRUE))

  if(length(complex_events) > 0){
    for(i in 1:length(complex_events)){
      ce = complex_events[i]
      #mo = t(apply(mat_origin, 2, rev))
      ce_idx = which(mo == ce, arr.ind = TRUE)

      ce = unlist(strsplit(x = ce, split = ";", fixed = TRUE))

      nm_temp = matrix(NA, nrow = nrow(nm), ncol = ncol(nm))
      nm_temp[ce_idx] = 0
      image(x = 1:nrow(nm_temp), y = 1:ncol(nm_temp), z = nm_temp, axes = FALSE, xaxt="n",
            yaxt="n", xlab="", ylab="", col = vc_col[ce[2]], add = TRUE)
      #points(ce_idx, pch= 15, col= vc_col[ce[1]])
      ce_idx = which(t(nm_temp) == 0, arr.ind = TRUE)
      for(i in seq_len(nrow(ce_idx))){
        rowi = ce_idx[i,1]
        coli = ce_idx[i,2]
        rect(xleft = coli-0.5, ybottom = rowi-0.25, xright = coli+0.5, ytop = rowi+0.25, col = vc_col[ce[1]], border = NA, lwd = 0)
      }
    }
  }

  del_idx = which(mo == "Del", arr.ind = TRUE)
  amp_idx = which(mo == "Amp", arr.ind = TRUE)

  if(nrow(amp_idx) > 0){
    nm_temp = matrix(NA, nrow = nrow(nm), ncol = ncol(nm))
    nm_temp[amp_idx] = 0
    image(x = 1:nrow(nm_temp), y = 1:ncol(nm_temp), z = nm_temp, axes = FALSE, xaxt="n",
          yaxt="n", xlab="", ylab="", col = bgCol, add = TRUE)
    amp_idx = which(t(nm_temp) == 0, arr.ind = TRUE)
    for(i in seq_len(nrow(amp_idx))){
      rowi = amp_idx[i,1]
      coli = amp_idx[i,2]
      rect(xleft = coli-0.5, ybottom = rowi-0.25, xright = coli+0.5, ytop = rowi+0.25, col = vc_col['Amp'], border = NA, lwd = 0)
    }
  }

  if(nrow(del_idx) > 0){
    nm_temp = matrix(NA, nrow = nrow(nm), ncol = ncol(nm))
    nm_temp[del_idx] = 0
    image(x = 1:nrow(nm_temp), y = 1:ncol(nm_temp), z = nm_temp, axes = FALSE, xaxt="n",
          yaxt="n", xlab="", ylab="", col = bgCol, add = TRUE)
    del_idx = which(t(nm_temp) == 0, arr.ind = TRUE)
    for(i in seq_len(nrow(del_idx))){
      rowi = del_idx[i,1]
      coli = del_idx[i,2]
      rect(xleft = coli-0.5, ybottom = rowi-0.25, xright = coli+0.5, ytop = rowi+0.25, col = vc_col['Del'], border = NA, lwd = 0)
    }
  }

  #Draw if any additional features are requested
  additionalFeature_legend = FALSE
  if(!is.null(additionalFeature)){
    if(length(additionalFeature) < 2){
      stop("additionalFeature must be of length two. See ?oncoplot for details.")
    }
    af_dat = subsetMaf(maf = maf, genes = rownames(numMat), tsb = colnames(numMat), fields = additionalFeature[1], includeSyn = FALSE, mafObj = FALSE)
    if(length(which(colnames(af_dat) == additionalFeature[1])) == 0){
      message(paste0("Column ", additionalFeature[1], " not found in maf. Here are available fields.."))
      print(getFields(maf))
      stop()
    }
    colnames(af_dat)[which(colnames(af_dat) == additionalFeature[1])] = 'temp_af'
    af_dat = af_dat[temp_af %in% additionalFeature[2]]
    if(nrow(af_dat) == 0){
      warning(paste0("No samples are enriched for ", additionalFeature[2], " in ", additionalFeature[1]))
    }else{
      af_mat = data.table::dcast(data = af_dat, Tumor_Sample_Barcode ~ Hugo_Symbol, value.var = "temp_af", fun.aggregate = length)
      af_mat = as.matrix(af_mat, rownames = "Tumor_Sample_Barcode")

      nm = t(apply(numMat, 2, rev))

      lapply(seq_len(nrow(af_mat)), function(i){
        af_i = af_mat[i,, drop = FALSE]
        af_i_genes = colnames(af_i)[which(af_i > 0)]
        af_i_sample = rownames(af_i)

        lapply(af_i_genes, function(ig){
          af_i_mat = matrix(c(which(rownames(nm) == af_i_sample),
                              which(colnames(nm) == ig)),
                            nrow = 1)
          points(af_i_mat, pch = additionalFeaturePch, col= additionalFeatureCol, cex = additionalFeatureCex)
        })
      })
      additionalFeature_legend = TRUE
    }
  }

  #Add grids
  abline(h = (1:ncol(nm)) + 0.5, col = borderCol, lwd = sepwd_genes)
  abline(v = (1:nrow(nm)) + 0.5, col = borderCol, lwd = sepwd_samples)
  title(title, cex.main = title_size, outer = FALSE, font = 2)

  # mtext(text = colnames(nm), side = 2, at = 1:ncol(nm),
  #       font = 3, line = 0.4, cex = fontSize, las = 2)
  if(plot2){
    mtext(text = rev(percent_alt), side = 4, at = 1:ncol(nm),
          font = 1, line = 0.4, cex = fontSize, las = 2, adj = 0)
    if(showBarcodes){
      text(x =1:nrow(nm), y = 0.40,
           labels = rownames(nm), srt = 90, font = 1,
           cex = barcode_size, adj = 1)
    }
  }else{
    mtext(text = rev(percent_alt), side = 2, at = 1:ncol(nm),
          font = 1, line = 0.4, cex = fontSize, las = 2, adj = 1)
    if(showBarcodes){
      text(x =1:nrow(nm), y = 0.40,
           labels = rownames(nm), srt = 90, font = 1,
           cex = barcode_size, adj = 1)
    }
  }

  #Color codes for annoations
  if(!is.null(clinicalFeatures)){
    clini_lvls = as.character(unlist(lapply(annotation, function(x) unique(as.character(x)))))

    if(is.null(annotationColor)){
      annotationColor = list()
      for(i in 1:ncol(annotation)){
        ann_lvls = levels(annotation[,i])
        if(length(ann_lvls) <= 9){
          ann_lvls_cols = RColorBrewer::brewer.pal(n = 9, name = 'Set1')[1:length(ann_lvls)]
          names(ann_lvls_cols) = ann_lvls
          annotationColor[[i]] = ann_lvls_cols
        }else{
          ann_lvls_cols = colors()[sample(x = 1:100, size = length(ann_lvls), replace = FALSE)]
          names(ann_lvls_cols) = ann_lvls
          annotationColor[[i]] = ann_lvls_cols
        }
      }
      names(annotationColor) = colnames(annotation)
    }

    anno_cols = c()
    for(i in 1:length(annotationColor)){
      anno_cols = c(anno_cols, annotationColor[[i]])
    }

    clini_lvls = clini_lvls[!is.na(clini_lvls)]
    names(clini_lvls) = 1:length(clini_lvls)
    temp_rownames = rownames(annotation)
    annotation = data.frame(lapply(annotation, as.character),
                            stringsAsFactors = FALSE, row.names = temp_rownames)

    for(i in 1:length(clini_lvls)){
      annotation[annotation == clini_lvls[i]] = names(clini_lvls[i])
    }

    annotation = data.frame(lapply(annotation, as.numeric), stringsAsFactors=FALSE, row.names = temp_rownames)

    annotation = annotation[colnames(numMat), ncol(annotation):1, drop = FALSE]

    if(plot2){
      par(mar = c(0, 1, 0, 5))
    }else{
      par(mar = c(0, 5, 0, 1))
    }

    image(x = 1:nrow(annotation), y = 1:ncol(annotation), z = as.matrix(annotation),
          axes = FALSE, xaxt="n", yaxt="n", bty = "n",
          xlab="", ylab="", col = "white") #col = "#FC8D62"

    #Plot for all variant classifications
    for(i in 1:length(names(clini_lvls))){
      anno_code = clini_lvls[i]
      col = anno_cols[anno_code]
      #temp_anno = t(apply(annotation, 2, rev))
      temp_anno = as.matrix(annotation)
      temp_anno[temp_anno != names(anno_code)] = NA
      suppressWarnings(image(x = 1:nrow(temp_anno), y = 1:ncol(temp_anno), z = temp_anno,
            axes = FALSE, xaxt="n", yaxt="n", xlab="", ylab="", col = col, add = TRUE))
    }

    #Add grids
    abline(h = (1:ncol(nm)) + 0.5, col = "white", lwd = sepwd_genes)
    abline(v = (1:nrow(nm)) + 0.5, col = "white", lwd = sepwd_samples)
    if(plot2){
      mtext(text = colnames(annotation), side = 4,
            font = 1, line = 0.4, cex = fontSize, las = 2, at = 1:ncol(annotation))
    }else{
      mtext(text = colnames(annotation), side = 2,
            font = 1, line = 0.4, cex = fontSize, las = 2, at = 1:ncol(annotation))
    }

    return(annotationColor)
  }
}

get_m12_annotation_colors = function(a1 = NULL, a1_cf = NULL,
                                 a2 = NULL , a2_cf = NULL){

  a1 = parse_annotation_dat(a1, a1_cf)
  a2 = parse_annotation_dat(a2, a2_cf)

  com_anno = intersect(colnames(a1), colnames(a2))
  cf_cols = list()

  if(length(com_anno) > 0){
    for(i in 1:length(com_anno)){
      cf_temp = com_anno[i]
      com_clini_lvls = unique(c(as.character(unlist(lapply(a1[,cf_temp, drop = FALSE], function(x) unique(as.character(x))))),
                         as.character(unlist(lapply(a2[,cf_temp, drop = FALSE], function(x) unique(as.character(x)))))))
      if(length(com_clini_lvls) <= 9){
        ann_lvls_cols = RColorBrewer::brewer.pal(n = 9, name = 'Set1')[1:length(com_clini_lvls)]
      }else{
        ann_lvls_cols = colors()[sample(x = 1:100, size = length(com_clini_lvls), replace = FALSE)]
      }

      cf_cols[[i]] = ann_lvls_cols
      names(cf_cols[[i]]) = com_clini_lvls
      #print(cf_cols)
    }
  }
  names(cf_cols) = com_anno

  a1_rest = a1[,colnames(a1)[!colnames(a1) %in% com_anno], drop = FALSE]
  a2_rest = a2[,colnames(a2)[!colnames(a2) %in% com_anno], drop = FALSE]

  a1_rest_cols = list()
  if(ncol(a1_rest) > 0){
    for(i in 1:ncol(a1_rest)){
      ann_lvls = unique(as.character(a1_rest[,i]))
      if(length(ann_lvls) <= 9){
        ann_lvls_cols = RColorBrewer::brewer.pal(n = 9, name = 'Set1')[1:length(ann_lvls)]
      }else{
        ann_lvls_cols = colors()[sample(x = 1:100, size = length(ann_lvls), replace = FALSE)]
      }
      a1_rest_cols[[i]] = ann_lvls_cols
      names(a1_rest_cols[[i]]) = ann_lvls
    }
  }
  names(a1_rest_cols) = colnames(a1_rest)

  a2_rest_cols = list()
  if(ncol(a2_rest) > 0){
    for(i in 1:ncol(a2_rest)){
      ann_lvls = unique(as.character(a2_rest[,i]))
      if(length(ann_lvls) <= 9){
        ann_lvls_cols = RColorBrewer::brewer.pal(n = 9, name = 'Set1')[1:length(ann_lvls)]
      }else{
        ann_lvls_cols = colors()[sample(x = 1:100, size = length(ann_lvls), replace = FALSE)]
      }
      a2_rest_cols[[i]] = ann_lvls_cols
      names(a2_rest_cols[[i]]) = ann_lvls
    }
  }
  names(a2_rest_cols) = colnames(a2_rest)
  #print(c(cf_cols, a1_rest_cols, a2_rest_cols))

  return(c(cf_cols, a1_rest_cols, a2_rest_cols))
}
