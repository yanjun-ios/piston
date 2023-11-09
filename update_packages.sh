#!/bin/bash

  repo="piston"
  # GitHub Token
  token="xxxxxxx"
  # owner
  owner="yanjun-ios"
  # Release名
  release_name="Packages"
  # 本地附件目录
  attach_dir="/opt/pkgs"
  # ReleaseId
  release_id=""

upload_assets(){
  release_id=$1
  file=$2
  echo "-----"
  echo $release_id $file
  # 上传文件
  upload_url=$(curl -H "Authorization: token $token" \
    -H "Content-Type: application/gzip" \
    https://uploads.github.com/repos/$owner/$repo/releases/$release_id/assets?name=$(basename $file) \
    --data-binary @$file > /dev/null)

  # 添加为Release附件
  curl -X POST -s -H "Authorization: token $token" \
    -H "Content-Type: application/json" \
    -d '{"name":"'$(basename $file)'","url":"'$upload_url'"}' \
    https://api.github.com/repos/$owner/$repo/releases/$release_id/assets > /dev/null
}

release_to_github(){
  # 获取 release_id
  if [ "x"${release_id} == "x" ]; then
      # 判断release是否存在
      release_exist=$(curl -s -H "Authorization: token $token" https://api.github.com/repos/$owner/$repo/releases/tags/$release_name | jq '.id')

      if [ -z "$release_exist" ]; then
        # 不存在则创建
        release_id=$(curl -s -X POST -H "Authorization: token $token" \
          -d '{"tag_name":"'"$release_name"'","name":"'"$release_name"'"}' \
          https://api.github.com/repos/$owner/$repo/releases | jq '.id')
      else
        # 存在则直接使用
        release_id=$release_exist
      fi
  fi

  # 遍历附件目录上传文件
  for file in $attach_dir/*.tar.gz; do
    echo "release: $file"
    upload_assets $release_id $file
  done
}

download_from_source(){

  cd $attach_dir

  rm -fr index && curl -s -L https://github.com/engineer-man/piston/releases/download/pkgs/index -o index

  count=1
  while read line; do

    if [ "x"$line == "x" ];then
      continue
    fi

    # 分割CSV字段
    IFS=',' read -ra fields <<< "$line"

    # 下载文件
    url="${fields[3]}"
    echo "${count}:${url}"
    filename=$(basename $url)
    curl -s -L -o "$filename" "$url"

    release_to_github

    rm -fr $filename

    ((count++))

  done < ./index

  sed -i 's!https://github.com/engineer-man/piston/releases/download/pkgs/!https://github.com/yanjun-ios/piston/releases/download/Packages/!g' index

  # 合并index文件
  mv index index_1 && curl -s -L https://github.com/yanjun-ios/piston/releases/download/Packages/index -o index_2

  cat index_1 index_2 | sort | uniq > index

  echo "upload the index file !"
  # 上传 index 文件
  upload_assets $release_id $attach_dir/index

}

download_from_source


