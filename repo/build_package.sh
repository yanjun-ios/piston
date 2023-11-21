#!/bin/bash

#set -x
# usage: sh build_package.sh python or sh build_package.sh python=2.7.18

repo="piston"
# GitHub Token
token="xxxxx"
# owner
owner="yanjun-ios"
# Release名
release_name="Packages"
# 本地附件目录
attach_dir="/piston/repo/"
# ReleaseId
release_id=""

all_assets=()
upload_assets(){
  release_id=$1
  file=$2
  echo "-----"
  echo "Upload File, Release Id: $release_id file name : $file"
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

# 获取所有的asset
get_all_assets() {
 page=1
 #release_id=128663575
 assets_url="https://api.github.com/repos/$owner/$repo/releases/${release_id}/assets?per_page=100"
 while :
 do
   local assets
   assets=$(curl -fsS -H "Authorization: token ${token}" "${assets_url}&page=${page}" | jq -r '.[] | "\(.name)-\(.id)"')
   name=$(echo ${assets[@]}| grep "pkg.tar.gz")
#   result=$(echo $name | grep "=")
   if [ $? -ne 0 ];then
    break;
   fi
   # 将当前页面的assets添加到数组中
   #mapfile -t assets < <(echo "$assets")
   for i in ${assets[*]}
   do
     # echo "this is i: "$i
     all_assets[${#all_assets[*]}]=${i}
   done
   ((page++))
 done
 echo "全量数组长度:${#all_assets[@]}"
}

# 根据文件名删除附件
delete_release_asset(){
  release_id=$1
  file_name=$2
  if [ ${#all_assets[@]} -eq 0 ]; then
   echo "assets 为空,请求全量assets"
   get_all_assets
  fi
  asset_id=""
  for element in "${all_assets[@]}"; do
    if [[ $element == *"$file_name"* ]]; then
      asset_id=$(echo $element | awk -F '-' '{print $NF}')
      break
    fi
  done
  echo "Delete File, file Name : $file_name asset_id ：$asset_id"
  if [ "$asset_id" == "" ]; then
    echo "Delete failed, No asset found with filename: $filename"
    return 1
  fi

  asset_url="https://api.github.com/repos/$owner/${repo}/releases/assets/${asset_id}"

  response=$(curl -s -X DELETE -H "Authorization: token ${token}" ${asset_url})

  if echo "$response" | grep -q '204 No Content'; then
    echo "Failed to delete asset: $response"
  else
    echo "Asset deleted successfully"
  fi
}

# 发布到github release中
release_to_github(){
  cd $attach_dir
  if [ ! -f *.tar.gz ];then
    echo "there is no packages to be released , exit 1"
    exit 1
  fi
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

  # 遍历 tar.gz 附件目录上传文件
  for file in *.tar.gz; do
    echo "release: $file"
    delete_release_asset $release_id $file
    upload_assets $release_id $file
  done

  # 合并index文件
  mv index index_1 && curl -s -L https://github.com/yanjun-ios/piston/releases/download/Packages/index -o index_2
  if [ $? -ne 0 ];then
    echo "download index file failed,exit 1"
    exit 1
  fi
  for file in *.tar.gz; do
    sed -i "/${file}$/d" index_2
  done
  cat index_1 index_2 | sort | uniq > index

  echo "upload the index file !"
  # 上传 index 文件
  delete_release_asset $release_id index
  upload_assets $release_id index

}

# 构建安装包
build_package(){
  cd /piston/packages
  echo "build packages from args..."
  for pkg in "$@"
  do
    shift
    if [ ! -d `echo $pkg | awk -F'=' '{print $1}'` ];then
      echo "Packages not found for $pkg"
      continue
    fi
    result=$(echo $pkg | grep "=")
    if [ $? -eq 0 ];then
      echo "install $pkg"
      pkgname=$(echo ${pkg/=/-})
      echo $pkgname
      make -j16 $pkgname.pkg.tar.gz PLATFORM=docker-debian
    else
      if [ -d "$pkg" ];then
        echo "install all version for $pkg"
        for version in $pkg/*;do
          version=$(echo $version | awk -F '/' '{print $2}')
          pkgname=${pkg}"-"${version}
          echo $pkgname
          make -j16 $pkgname.pkg.tar.gz PLATFORM=docker-debian
        done
      fi
    fi
  done

  if [ ! -f *.tar.gz ];then
    echo "there is no packages to be released , exit 1"
    exit 1
  fi
  cd /piston/repo
  echo "Creating index"
  ./mkindex.sh
  echo "Index created"

}

if [ $1 == "release" ];then
  release_to_github
else
  build_package $@
#  release_to_github
fi





