# Parsing captions and get chunk phrases out of them

## parsing dataset for extracting chunks

After pre-processing, data is organized as follows in _output_dir_:
```
output_dir/
  sentences.txt            # raw captions
  sentences.token          # tokenized captions
  sentences.final          # normalized captions
  sentences.chk            # chunk tags (output from SENNA)
  sentences.chksz          # reformatted chunk tags (one caption per line)
  sentences.chkszfinal     # normalized chunk tags
  nb.txt                   # number of captions per image
  id.txt                   # image ids
  vocab/
    NP.txt                 # noun phrase vocabulary
    VP.txt                 # verbal phrase vocabulary
    PP.txt                 # prepositional phrase vocabulary
  text/
    image_NP_ge10.txt      # noun phrases from image captions
    image_NP_ge10.index    # same as above, but with indices (for training purpose)
    image_VP_ge10.txt      # verbal phrases from image captions
    image_VP_ge10.index    # same as above, but with indices (for training purpose)
    image_PP_ge10.txt      # prepositional phrases from image captions
    image_PP_ge10.index    # same as above, but with indices (for training purpose)
  image/
    features.bin           # 2D torch.FloatTensor object with image features
    id.txt                 # image ids
  lookup/
    NP_400d_ge10.bin       # 400d noun phrase embeddings (2D torch.FloatTensor)
    VP_400d_ge10.bin       # 400d verbal phrase embeddings (2D torch.FloatTensor)
    PP_400d_ge10.bin       # 400d prepositional phrase embeddings (2D torch.FloatTensor)
```
In this example, we consider only phrases that appear at least 10 times in the
training dataset.

### parse input file
This step assumes that each input line contains the image id in first column,
then image captions in the next columns. Each column is separated by tabulation
character.
```
lua chunking/parse.lua "$input_file" "$output_dir"
```

### tokenize sentence
With Stanford tokenizer.
```
java -cp third_party/stanford-parser.jar \
  edu.stanford.nlp.process.PTBTokenizer \
  -preserveLines "$output_dir/sentences.txt" \
  > "$output_dir/sentences.token"
```

### normalize token for SENNA
Preparing text data for chunking with SENNA.
```
lua chunking/normalize_token.lua "$output_dir"
```

### do chunking with SENNA
```
cd third_party/senna
senna \
  -usrtokens \
  -chk \
  -notokentags \
  -brackettags \
  < "$output_dir/sentences.final" \
  > "$output_dir/sentences.chk"
cd ../..
```

### get chunk size
```
lua chunking/chunksize.lua "$output_dir"
```

### normalize phrases
Merging some phrases into longer verbal phrases or prepositional phrases.
```
lua chunking/normalize_phrases.lua "$output_dir"
```

## building vocabularies for phrases

### get noun phrases, verbal phrases and prepositional phrases
```
mkdir vocab
lua phrases/get_phrases.lua "NP" "$output_dir"
lua phrases/get_phrases.lua "VP" "$output_dir"
lua phrases/get_phrases.lua "PP" "$output_dir"
```

### associating phrases with images
Here a threshold can be set to remove rare phrases, and reduce the vocabulary
size at the same time.
```
lua phrases/image_phrases.lua "NP" "$output_dir" 10
lua phrases/image_phrases.lua "VP" "$output_dir" 10
lua phrases/image_phrases.lua "PP" "$output_dir" 10
```

# Training a bilinear model for learning metric between images and phrases

## get phrase embeddings
This step assumes that word embeddings have been computed beforehand.
Word embeddings are stored in binary file containing a 2D torch.FloatTensor.
A plain text file contains the word vocabulary (one word per line).
```
for p in {"NP","VP","PP"}
do
  th phrases/embeddings.lua \
    -emb emb_file.bin \
    -vocab word_file.txt \
    -pfsz 400 \
    -t 10 \
    -phr $p
done
```

## do training

```
th bilinear/train.lua \
  -data "$output_dir" \
  -out "$exp_dir" \
  -pfsz 400 \
  -neg 15 \
  -lr 0.00025 \
  -nbiter 100 \
  -epoch 100000 \
```



