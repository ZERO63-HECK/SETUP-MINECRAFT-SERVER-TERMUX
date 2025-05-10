#!/bin/bash

# Definisikan warna untuk tampilan
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# Header Fungsi
show_header() {
    clear
    echo -e "${CYAN}"
    echo -e "         SERVER MINECRAFT TERMUX       "
    echo -e ""
    echo -e "     Paper | Vanilla | Purpur | JDK Setup  "
    echo -e ""
    echo -e "            BY 2025 ZERO63-HECK                  "
    echo -e "${NC}"
}


# Pilih versi Minecraft dan Java
pilih_versi_dari_list() {
    versi_list=("$@")
    echo -e "\n${CYAN}Pilih Versi Minecraft:${NC}"
    for i in "${!versi_list[@]}"; do
        echo -e "${YELLOW}$((i+1)).${NC} ${versi_list[$i]}"
    done
    echo ""
    read -p ">> Masukkan nomor versi: " pilih
    mcver="${versi_list[$((pilih-1))]}"
}

# Install Java otomatis berdasarkan versi Minecraft
install_java_for_version() {
    if [[ "$mcver" == 1.2* || "$mcver" == 1.1[7-9]* || "$mcver" == 1.20* ]]; then
        JDK="openjdk-17"
        java_info="Java 17"
    elif [[ "$mcver" == 1.21* ]]; then
        JDK="openjdk-21"
        java_info="Java 21"
    else
        JDK="openjdk-8"
        java_info="Java 8"
    fi

    echo -e "${CYAN}[] Minecraft $mcver membutuhkan $java_info${NC}"

    # Install jika belum ada
    if ! dpkg -l | grep -q "$JDK"; then
        echo -e "${YELLOW}Menginstal $JDK...${NC}"
        pkg update -y && pkg install $JDK -y
    else
        echo -e "${GREEN}[] $JDK sudah terinstal.${NC}"
    fi
}

# Download dan setup server Minecraft
download_and_create() {
    mkdir -p "$dirname"
    cd "$dirname" || exit
    echo -e "${YELLOW}[] Mendownload server...${NC}"
    curl -L "$1" -o server.jar

    echo -e "${YELLOW}[] Membuat run_server.sh...${NC}"
    cat <<EOF > run_server.sh
#!/bin/bash
echo "Menjalankan Minecraft Server ($mcver)..."
java -Xms1G -Xmx2G -jar server.jar nogui
EOF
    chmod +x run_server.sh

    echo "eula=true" > eula.txt

    echo -e "\n${GREEN} Berhasil! Jalankan: cd $dirname && bash run_server.sh${NC}"
    echo -e "${CYAN} Menjalankan server...${NC}"
    bash run_server.sh
}

# Install Java manual
install_java_manual() {
    echo -e "${CYAN}Pilih versi OpenJDK yang ingin diinstall:${NC}"
    echo -e "${YELLOW}1.${NC} OpenJDK 8"
    echo -e "${YELLOW}2.${NC} OpenJDK 17"
    echo -e "${YELLOW}3.${NC} OpenJDK 21"
    echo ""
    read -p ">> Pilih: " jdk
    case $jdk in
        1) pkg install openjdk-8 -y ;;
        2) pkg install openjdk-17 -y ;;
        3) pkg install openjdk-21 -y ;;
        *) echo -e "${RED} Pilihan tidak valid.${NC}" ;;
    esac
}

# Install Server Minecraft
install_server() {
    echo -e "${CYAN}Pilih jenis server Minecraft:${NC}"
    echo -e "${YELLOW}1.${NC} PaperMC "
    echo -e "${YELLOW}2.${NC} Vanilla Minecraft"
    echo -e "${YELLOW}3.${NC} Purpur "
    echo ""
    read -p ">> Masukkan pilihan [1/2/3]: " jenis

    case $jenis in
        1)
            echo -e "${CYAN}[•] Memilih PaperMC...${NC}"
            data=$(curl -s https://api.papermc.io/v2/projects/paper)
            versions=($(echo "$data" | grep -oP '"versions":\[\K[^\]]+' | tr -d '"' | tr ',' '\n'))
            pilih_versi_dari_list "${versions[@]}"
            build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$mcver" | grep -oP '"builds":\[\K[^\]]+' | tr -d '",' | tail -n1)
            link="https://api.papermc.io/v2/projects/paper/versions/$mcver/builds/$build/downloads/paper-$mcver-$build.jar"
            dirname="Paper-$mcver"
            install_java_for_version
            download_and_create "$link"
            ;;
        2)
            echo -e "${CYAN}[•] Memilih Vanilla Minecraft...${NC}"
            manifest=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json)
            versions=($(echo "$manifest" | grep -oP '"id":\s*"\K[^"]+'))
            pilih_versi_dari_list "${versions[@]}"
            url=$(echo "$manifest" | grep -oP '"url":\s*"\K[^"]+(?=",\s*"id":\s*"'$mcver'")')
            server_url=$(curl -s "$url" | grep -oP '"server":\s*{[^}]*"url":\s*"\K[^"]+')
            dirname="Vanilla-$mcver"
            install_java_for_version
            download_and_create "$server_url"
            ;;
        3)
            echo -e "${CYAN}[•] Memilih Purpur...${NC}"
            data=$(curl -s https://api.purpurmc.org/v2/purpur)
            versions=($(echo "$data" | grep -oP '"versions":\[\K[^\]]+' | tr -d '"' | tr ',' '\n'))
            pilih_versi_dari_list "${versions[@]}"
            build=$(curl -s "https://api.purpurmc.org/v2/purpur/$mcver" | grep -oP '"builds":\[\K[^\]]+' | tr -d '",' | tail -n1)
            link="https://api.purpurmc.org/v2/purpur/$mcver/$build/download"
            dirname="Purpur-$mcver"
            install_java_for_version
            download_and_create "$link"
            ;;
        *)
            echo -e "${RED} Pilihan tidak valid.${NC}" ;;
    esac
}

# Menu Utama
while true; do
    show_header
    echo -e "${YELLOW}1.${NC} Install Server Minecraft"
    echo -e "${YELLOW}2.${NC} Install OpenJDK Manual"
    echo -e "${YELLOW}3.${NC} Keluar"
    echo ""
    read -p ">> Pilih menu: " menu

    case $menu in
        1) install_server ;;
        2) install_java_manual ;;
        3) echo -e "${GREEN}Sampai jumpa!${NC}"; exit ;;
        *) echo -e "${RED} Pilihan tidak valid.${NC}" ;;
    esac

    echo -e "${YELLOW}Tekan Enter untuk kembali ke menu utama...${NC}"
    read
done
