#!/bin/bash

# if extract not exist then use own function support zsh and bash
if ! declare -f extract >/dev/null 2>&1; then
	extract() {
		local pwd="$PWD"
		local remove_archive=1
		local success=0

		if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
			remove_archive=0
			shift
		fi

		if (($# == 0)); then
			cat >&2 <<'EOF'
Usage: extract [-option] [file ...]

Options:
    -r, --remove    Remove archive after unpacking.
EOF
			return 1
		fi

		while (($# > 0)); do
			if [[ ! -f "$1" ]]; then
				echo "extract: '$1' is not a valid file" >&2
				shift
				continue
			fi

			local file="$1"
			local full_path="$(realpath "$1")"
			local extract_dir="${file##*/}"
			extract_dir="${extract_dir%.*}"

			# Handle .tar extensions
			if [[ "$extract_dir" =~ \.tar$ ]]; then
				extract_dir="${extract_dir%.tar}"
			fi

			if [[ -e "$extract_dir" ]]; then
				local rnd="$(head /dev/urandom | tr -dc a-z0-9 | head -c 5)"
				extract_dir="${extract_dir}-${rnd}"
			fi

			mkdir -p "$extract_dir"
			cd "$extract_dir"
			echo "extract: extracting to $extract_dir" >&2

			case "${file,,}" in
			*.tar.gz | *.tgz)
				if command -v pigz >/dev/null 2>&1; then
					tar -I pigz -xvf "$full_path"
				else
					tar zxvf "$full_path"
				fi
				;;
			*.tar.bz2 | *.tbz | *.tbz2)
				if command -v pbzip2 >/dev/null 2>&1; then
					tar -I pbzip2 -xvf "$full_path"
				else
					tar xvjf "$full_path"
				fi
				;;
			*.tar.xz | *.txz)
				if command -v pixz >/dev/null 2>&1; then
					tar -I pixz -xvf "$full_path"
				else
					if tar --help 2>&1 | grep -q "\-\-xz"; then
						tar --xz -xvf "$full_path"
					else
						xzcat "$full_path" | tar xvf -
					fi
				fi
				;;
			*.tar.zma | *.tlz)
				if tar --help 2>&1 | grep -q "\-\-lzma"; then
					tar --lzma -xvf "$full_path"
				else
					lzcat "$full_path" | tar xvf -
				fi
				;;
			*.tar.zst | *.tzst)
				if tar --help 2>&1 | grep -q "\-\-zstd"; then
					tar --zstd -xvf "$full_path"
				else
					zstdcat "$full_path" | tar xvf -
				fi
				;;
			*.tar) tar xvf "$full_path" ;;
			*.tar.lz) tar xvf "$full_path" ;;
			*.tar.lz4) lz4 -c -d "$full_path" | tar xvf - ;;
			*.gz)
				if command -v pigz >/dev/null 2>&1; then
					pigz -cdk "$full_path" >"${file%.*}"
				else
					gunzip -ck "$full_path" >"${file%.*}"
				fi
				;;
			*.bz2)
				if command -v pbzip2 >/dev/null 2>&1; then
					pbzip2 -d "$full_path"
				else
					bunzip2 "$full_path"
				fi
				;;
			*.xz) unxz "$full_path" ;;
			*.lz4) lz4 -d "$full_path" ;;
			*.lzma) unlzma "$full_path" ;;
			*.z) uncompress "$full_path" ;;
			*.zip | *.war | *.jar | *.ear | *.sublime-package | *.ipa | *.ipsw | *.xpi | *.apk | *.aar | *.whl | *.vsix | *.crx | *.pk3 | *.pk4)
				unzip "$full_path"
				;;
			*.rar) unrar x -ad "$full_path" ;;
			*.rpm) rpm2cpio "$full_path" | cpio --quiet -id ;;
			*.7z | *.7z.[0-9]* | *.pk7) 7za x "$full_path" ;;
			*.deb)
				mkdir -p "control" "data"
				ar vx "$full_path" >/dev/null
				cd control
				extract ../control.tar.*
				cd ../data
				extract ../data.tar.*
				cd ..
				rm -f *.tar.* debian-binary
				;;
			*.zst) unzstd --stdout "$full_path" >"${file%.*}" ;;
			*.cab | *.exe) cabextract "$full_path" ;;
			*.cpio | *.obscpio) cpio -idmvF "$full_path" ;;
			*)
				echo "extract: '$file' cannot be extracted" >&2
				success=1
				;;
			esac

			success=$?
			if [[ $success -eq 0 ]] && [[ $remove_archive -eq 0 ]]; then
				rm "$full_path"
			fi

			shift
			cd "$pwd"

			# Check if we need to move contents up a level
			if [[ -d "$extract_dir" ]]; then
				local content_count=$(find "$extract_dir" -maxdepth 1 -mindepth 1 | wc -l)

				if [[ $content_count -eq 1 ]]; then
					local single_item=$(find "$extract_dir" -maxdepth 1 -mindepth 1)
					local item_name=$(basename "$single_item")

					if [[ "$item_name" != "$extract_dir" ]]; then
						if [[ ! -e "$item_name" ]]; then
							mv "$single_item" .
							rmdir "$extract_dir"
						fi
					fi
				elif [[ $content_count -eq 0 ]]; then
					rmdir "$extract_dir"
				fi
			fi
		done
	}
fi

# alias own e to extract
if ! type e >/dev/null 2>&1; then
	alias e=extract
fi
