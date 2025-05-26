#!/bin/bash

# interactive bash script that automates some steps and walks you through others
# to install dqx and dqxclarity onto your steam deck.

function download_file() {
    local filename="${1}"
    local url="${2}"

    echo "Downloading ${filename}. Please be patient."
    curl --location -o "${HOME}/Downloads/${filename}" "${url}"
    if [ $? -ne 0 ]; then
        whiptail --title "File download" --msgbox "Failed to download ${filename} from ${url}."
        continue
    fi
}

function get_wine_prefix() {
    if [ ! -f "${HOME}/.config/dqxclarity/wineprefix" ]; then
        return
    fi

    wine_prefix=$(cat "${HOME}/.config/dqxclarity/wineprefix")

    if [ -z ${wine_prefix} ]; then
        return
    fi

    echo "${wine_prefix}"
}

function check_kwrite() {
    hash kwrite 2>/dev/null
    if [ $? -ne 0 ]; then
        whiptail --title "kwrite" --msgbox "kwrite is not installed. Please install it to edit the user settings file." 8 50
        continue
    fi
}

while true; do
    CHOICE=$(whiptail \
        --title "DQX + dqxclarity install" \
        --menu "Welcome to the dqxclarity installer. Choose an option using the arrow keys and select the option with enter." 17 58 9 \
        "1" "Install DQX" \
        "2" "Install DQX expansions" \
        "3" "Install English launcher/config" \
        "4" "Install Python" \
        "5" "Install dqxclarity" \
        "6" "Edit user_settings.ini" \
        "7" "Edit launch options" \
        "8" "Check install validity" \
        "9" "Exit" 3>&1 1>&2 2>&3
    )

    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        echo "User canceled."
        break
    fi

    case $CHOICE in
        # install dqx
        1)
            whiptail \
                --title "DQX Install" \
                --yesno "This will download the DQX installers and help you set up DQX on your Steam Deck.\n\nSelect \"Yes\" to start and \"No\" to cancel." 11 60
            response=$?

            if [ ${response} -ne 0 ]; then
                continue
            fi

            download_file "dqxinstaller_ft.exe" "https://download.dqx.jp/dqlaunc/DQXInstaller_ft.exe"

            clear
            echo "==> Follow these instructions! <=="
            echo ""
            echo "IF THIS PROCESS IS INTERRUPTED, YOU WILL NEED TO START FROM THE BEGINNING."
            echo ""
            echo "- Add a new non-steam game through Steam. Click "Browse" and navigate to this directory:"
            echo ""
            echo "    ${HOME}/Downloads"
            echo ""
            echo "- Select \"dqxinstaller_ft.exe\" and click \"Open\". Click \"Add Selected Programs\" to add it to your library"
            echo "- Once the game is added, right-click it and select \"Properties...\""
            echo "- Select \"Compatability\" and check \"Force the use of a specific Steam Play compatability tool\""
            echo "- Click the drop down and select \"Proton 9.0-4\" (or whatever version of Proton 9.0 is there)"
            echo "- Close out of the window, make sure \"dqxinstaller_ft.exe\" is selected and click \"Play\""
            echo ""
            echo "Once you've clicked \"Play\", the script will automatically continue."

            # while the user is setting up steam, we're going to scan the compatdata directory, which is where
            # the wine prefix folder will eventually get created after they click play to launch the game with proton.
            watch_dir="/home/deck/.steam/steam/steamapps/compatdata"
            declare -A seen_folders

            # get all folders inside of watch_dir
            while IFS= read -r -d '' folder; do
                seen_folders["$(basename "${folder}")"]=1
            done < <(find "$watch_dir" -mindepth 1 -maxdepth 1 -type d -print0)

            # scan for changes to the directory. we assume the first new folder we detect is our wine prefix folder.
            while true; do
                while IFS= read -r -d '' folder; do
                    base=$(basename "$folder")
                    if [ -z "${seen_folders[${base}]}" ]; then
                        wine_prefix="${base}"
                        echo "Wine prefix folder detected: ${wine_prefix}"

                        # store the wine_prefix id in the user's local config directory.
                        # we'll use this as state if we ever need it.
                        mkdir -p "${HOME}/.config/dqxclarity"
                        echo "${wine_prefix}" > "${HOME}/.config/dqxclarity/wineprefix"
                        break 2
                    fi
                done < <(find "$watch_dir" -mindepth 1 -maxdepth 1 -type d -print0)

                sleep 1
            done

            clear
            whiptail \
                --title "DQX Install" \
                --msgbox "Go ahead and run through the DQX installer.\n\nDo not change the default install directory.\n\nPress enter AFTER you have finished the installation, closed the window and Steam no longer says the game is running." 13 75

            dqx_install_path="/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/SquareEnix/DRAGON QUEST X"

            if [ ! -d "${dqx_install_path}" ]; then
                whiptail --title "DQX Install Failed" --msgbox "DQX installation was not found. You will need to start this process over. Make sure you follow all instructions! \n\nDelete the non-steam games you added and try again." 11 60
                continue
            fi

            clear
            echo "==> Follow these instructions! <=="
            echo ""
            echo "Now that the game is installed, we need to patch it!"
            echo "Create a new non-steam game and point it to DQXBoot.exe. To do this:"
            echo ""
            echo "- Open Steam"
            echo "- Add a new non-steam game"
            echo "- Click \"Browse...\""
            echo "- Navigate to this path at the top:"
            echo ""
            echo "    /home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/SquareEnix/DRAGON QUEST X/Boot"
            echo ""
            echo "- Select \"DQXBoot.exe\""
            echo "- Click \"Add Selected Programs\""
            echo "- Once the game is added, right-click \"DQXBoot.exe\" from your library and select \"Properties...\""
            echo "- Select \"Compatability\" and check \"Force the use of a specific Steam Play compatability tool\""
            echo "- Click the drop down and select \"Proton 9.0-4\" (or whatever version of Proton 9.0 is there)"
            echo "- Close out of the window, make sure \"DQXBoot.exe\" is selected and click \"Play\""
            echo ""
            echo "This will launch the game and start the regular update process."
            echo ""
            echo "- After the first update completes, the window will close and the game will exit"
            echo "- You will need to click \"Play\" again to continue the update process"
            echo "- The DQXConfig window will open. It won't be in English - just click OK"
            echo "- The intro video will now play, but will not play properly. This is expected - just close it"
            echo "- The game will now start patching"
            echo ""
            echo "This part of the install process is complete, but make sure you let the game finish patching before proceeding with the other steps."
            read -p "Press ENTER to return to the main menu."
            continue
            ;;
        # install expansions
        2)
            wine_prefix=$(get_wine_prefix)
            if [ -z "${wine_prefix}" ]; then
                whiptail \
                    --title "DQX Expansion Installer" \
                    --msgbox "Wine prefix not found. Please install DQX with option \"1\" first." 8 50
                continue
            fi

            clear
            echo "Unfortunately, this process cannot be automated as we can't distribute the expansion installers."
            echo "However, you can grab the download from wherever you purchased it from (Amazon, SQEX store) or from the DQX WW Discord."
            echo "Once you've downloaded the expansion onto your Steam Deck, follow these steps:"
            echo ""
            echo "**************************************************************"
            echo "This assumes you're installing the V1-7 All-In-One installer."
            echo "If you're using a different installer, which file to choose may differ."
            echo "**************************************************************"
            echo ""
            echo "- Open Steam"
            echo "- Add a new non-steam game"
            echo "- Click \"Browse...\""
            echo "- Navigate to the directory where you downloaded the expansion installer"
            echo "    - If this file is a zip file, make sure you extract it first!"
            echo "- The top level expansion installer should have a file named \"Setup.exe\". Select this file"
            echo "- Click \"Add Selected Programs\""
            echo "- Once the game is added, right-click \"Setup.exe\" from your library and select \"Properties...\""
            echo "- At the top of this window, give the game a name like \"DQX Expansion Installers\""
            echo "- In the \"LAUNCH OPTIONS\" field, paste the following as one line:"
            echo ""
            echo "    STEAM_COMPAT_DATA_PATH=\"/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}\" %command%"
            echo ""
            echo "- Select \"Compatability\" and check \"Force the use of a specific Steam Play compatability tool\""
            echo "- Click the drop down and select \"Proton 9.0-4\" (or whatever version of Proton 9.0 is there)"
            echo "- Close out of the window, make sure \"Setup.exe\" is selected and click \"Play\""
            echo ""
            echo "This will launch the installers for each expansion. Click the light-blue button to install each version."
            echo "You will be prompted to install the first one. After it's completed, the others will install automatically."
            echo "Wait until all of the expansion windows have a blue slime icon that say \"OK\"."
            echo "Once the installers are complete, a window will pop up. Click \"OK\". You can now close the setup window."
            echo ""
            read -p "Press ENTER to exit this prompt and return to the main menu."
            continue
            ;;
        # install english launcher/config
        3)
            whiptail \
                --title "DQX Config/Launcher" \
                --yesno "This option replaces DQX's launcher/config with their translated counterparts. It requires the game to already be installed from option 1.\n\nSelect \"Yes\" to start and \"No\" to cancel." 11 60
            response=$?

            if [ ${response} -ne 0 ]; then
                continue
            fi

            wine_prefix=$(get_wine_prefix)
            dqx_install_path="${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/SquareEnix/DRAGON QUEST X"

            if [ ! -d "${dqx_install_path}" ]; then
                echo "DQX installation was not found in wine prefix ${wine_prefix}."
                echo "This could happen if the install was interrupted or was never attempted."
                echo "Install the game with option #1 first before attempting this step."
                read -p "Press ENTER to return to the main menu."
                exit 1
            fi

            download_file "DQXLauncher.exe" "https://github.com/dqx-translation-project/dqx_en_launcher/releases/latest/download/DQXLauncher.exe"
            download_file "DQXConfig.exe" "https://github.com/dqx-translation-project/dqx_en_config/releases/latest/download/DQXConfig.exe"

            mv "${HOME}/Downloads/DQXLauncher.exe" "${dqx_install_path}/Boot/DQXLauncher.exe"
            mv "${HOME}/Downloads/DQXConfig.exe" "${dqx_install_path}/Game/DQXConfig.exe"

            whiptail \
                --title "DQX Config/Launcher" \
                --msgbox "DQXLauncher.exe and DQXConfig.exe have been updated." 8 40
            continue
            ;;
        # install python
        4)
            whiptail \
                --title "Python Install" \
                --yesno "This will download and install Python, which is required for dqxclarity to function.\n\nSelect \"Yes\" to start and \"No\" to cancel." 11 60
            response=$?

            if [ ${response} -ne 0 ]; then
                continue
            fi

            wine_prefix=$(get_wine_prefix)
            if [ -z "${wine_prefix}" ]; then
                whiptail \
                    --title "Python Install" \
                    --msgbox "Wine prefix not found. Please install DQX first." 8 50
                continue
            fi

            download_file "python-3.11.3.exe" "https://www.python.org/ftp/python/3.11.3/python-3.11.3.exe"

            clear
            echo "==> Follow these instructions! <=="
            echo ""
            echo "- Add a new non-steam game through Steam. Click "Browse" and navigate to this directory:"
            echo ""
            echo "    ${HOME}/Downloads"
            echo ""
            echo "- Select \"python-3.11.3.exe\" and click \"Open\". Click \"Add Selected Programs\" to add it to your library"
            echo "- Once the game is added, right-click it and select \"Properties...\""
            echo "- Under \"LAUNCH OPTIONS\", paste the following as one line into the field:"
            echo ""
            echo "    STEAM_COMPAT_DATA_PATH="/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}" %command% /passive InstallAllUsers=1 PrependPath=1 Include_doc=0 Include_tcltk=1 Include_test=0 Shortcuts=0"
            echo ""
            echo "- Select \"Compatability\" and check \"Force the use of a specific Steam Play compatability tool\""
            echo "- Click the drop down and select \"Proton 9.0-4\" (or whatever version of Proton 9.0 is there)"
            echo "- Close out of the window, make sure \"python-3.11.3.exe\" is selected and click \"Play\""
            echo ""
            echo "Once you've clicked \"Play\", Python will install automatically."
            echo ""
            read -p "After the installation is complete, press ENTER to validate the install."

            if [ ! -f "/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/Python311-32/python.exe" ]; then
                whiptail \
                    --title "Python Install Failed" \
                    --msgbox "Python installation was not found. Did it install successfully?" 11 60
                continue
            else
                whiptail \
                    --title "Python Install Success" \
                    --msgbox "Python installation was successful. Press ENTER to return to the main menu." 8 60
                continue
            fi
            ;;
        # install dqxclarity
        5)
            whiptail \
                --title "dqxclarity Install" \
                --yesno "This will download and setup dqxclarity.\n\nSelect \"Yes\" to start and \"No\" to cancel." 11 60
            response=$?

            if [ ${response} -ne 0 ]; then
                continue
            fi

            wine_prefix=$(get_wine_prefix)
            if [ -z "${wine_prefix}" ]; then
                whiptail \
                    --title "dqxclarity Install" \
                    --msgbox "Wine prefix not found. Please install DQX first." 8 50
                continue
            fi

            # start with a clean install each time this is run.
            rm -rf "${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser/dqxclarity"

            download_file "dqxclarity.zip" "https://github.com/dqx-translation-project/dqxclarity/releases/latest/download/dqxclarity.zip"
            mv "${HOME}/Downloads/dqxclarity.zip" "${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser"
            cd "${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser"
            unzip -qq dqxclarity.zip

            whiptail \
                --title "dqxclarity Install" \
                --msgbox "dqxclarity has been installed, but must be configured.\n\nUse options \"6\" and \"7\" to set up your API key and launch options." 10 60
            continue
            ;;
        # edit user_settings.ini
        6)
            user_settings_file="${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser/dqxclarity/user_settings.ini"
            if [ ! -f "${user_settings_file}" ]; then
                whiptail \
                    --title "Edit user_settings.ini" \
                    --msgbox "user_settings.ini file not found. Is dqxclarity installed?" 8 50
                continue
            fi

            check_kwrite

            whiptail \
                --title "Edit user_settings.ini" \
                --msgbox "A notepad-like window (KWrite) will open to allow you to enable a translation service and add an API key if applicable. Simply replace \"False\" with \"True\" for the service you want to use and paste your API key right after the equals sign." 12 60

            kwrite "${user_settings_file}"
            continue
            ;;
        # edit launch options
        7)
            wine_prefix=$(get_wine_prefix)
            if [ -z "${wine_prefix}" ]; then
                whiptail --title "dqxclarity Install" --msgbox "Wine prefix not found. Please install DQX first." 8 50
                continue
            fi

            user_choices=$(whiptail --title "dqxclarity Options" --checklist \
            "Select options to enable (use space to select; enter to confirm):" 11 75 4 \
            "p"  "Scan for player names"   ON \
            "n"  "Scan for NPC names"      ON \
            "c"  "Use API translation"     ON \
            "d"  "Update DAT translation"  ON 3>&1 1>&2 2>&3)

            concat_choices=$(echo ${user_choices} | tr -d '"' | tr -d ' ')
            if [ -n "${concat_choices}" ]; then
                concat_choices="-${concat_choices}"
            fi

            # it is important to use tabs over spaces for indenting here. otherwise, <<- doesn't work.
            cat <<-EOF > "/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser/run.bat"
				@echo off
				cd "C:\users\steamuser\dqxclarity"
				if not exist venv (
					echo Installing requirements. This may take a minute.
					python -m venv venv
					.\venv\Scripts\python.exe -m pip install -r requirements.txt
				)
				start "" .\venv\Scripts\python.exe main.py ${concat_choices}
				start "" "C:\Program Files (x86)\SquareEnix\DRAGON QUEST X\Boot\DQXBoot.exe"
			EOF

            whiptail \
                --title "Launch Options Updated" \
                --msgbox "Launch options have been updated." 7 40

            clear
            echo "==> Follow these instructions! <=="
            echo ""
            echo "*****************************************************************"
            echo "IF YOU HAVE ALREADY SET THIS UP IN STEAM, YOU DO NOT HAVE TO DO IT AGAIN!"
            echo "*****************************************************************"
            echo ""
            echo "You're not done yet! You need to add the launch script to steam to launch dqxclarity and DQX together."
            echo ""
            echo "- Add a new non-steam game through Steam. Click "Browse" and navigate to this directory:"
            echo ""
            echo "    /home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser/"
            echo ""
            echo "- Under the \"Filter\" dropdown at the bottom select \"All Files\""
            echo "- Select \"run.bat\" at the bottom and click \"Open\". Click \"Add Selected Programs\" to add it to your library"
            echo "- Once the game is added, right-click it and select \"Properties...\""
            echo "- At the top, give this shortcut a name, like: \"DQX+dqxclarity\""
            echo "- Under \"TARGET\", paste the following as one line into the field:"
            echo ""
            echo "    /home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/windows/system32/cmd.exe\" /C \"C:\users\steamuser\run.bat\""
            echo ""
            echo "- Under \"LAUNCH OPTIONS\", paste the following as one line into the field:"
            echo ""
            echo "    STEAM_COMPAT_DATA_PATH=\"/home/deck/.steam/steam/steamapps/compatdata/${wine_prefix}\" %command%"
            echo ""
            echo "- Select \"Compatability\" and check \"Force the use of a specific Steam Play compatability tool\""
            echo "- Click the drop down and select \"Proton 9.0-4\" (or whatever version of Proton 9.0 is there)"
            echo "- Close out of the window"
            echo ""
            echo "This is now the shortcut you will launch every time you want to play the game."
            echo "This will launch both dqxclarity and dqxboot at the same time."
            read -p "Press ENTER to return to the main menu."
            continue
            ;;
        # check install validity
        8)
            wine_prefix=$(get_wine_prefix)
            dqx_directory="${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/SquareEnix/DRAGON QUEST X/Game/Content/Data/data00000000.win32.dat0"
            python_directory="${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/Program Files (x86)/Python311-32/python.exe"
            dqxclarity_directory="${HOME}/.steam/steam/steamapps/compatdata/${wine_prefix}/pfx/drive_c/users/steamuser/dqxclarity"

            if [ -n "${wine_prefix}" ]; then
                wine_prefix_status="PASS"
            else
                wine_prefix_status="FAIL"
            fi

            if [ -f "${dqx_directory}" ]; then
                dqx_directory_status="PASS"
            else
                dqx_directory_status="FAIL"
            fi

            if [ -f "${python_directory}" ]; then
                python_directory_status="PASS"
            else
                python_directory_status="FAIL"
            fi

            if [ -d "${dqxclarity_directory}" ]; then
                dqxclarity_directory_status="PASS"
            else
                dqxclarity_directory_status="FAIL"
            fi

            whiptail \
                --title "Validation Check" \
                --msgbox "wine prefix.................${wine_prefix_status}\nDQX directory...............${dqx_directory_status}\nPython directory............${python_directory_status}\ndqxclarity directory........${dqxclarity_directory_status}" 10 50

            continue
            ;;
        # exit
        9)
            break
            ;;
    esac

    read -p "Press Enter to continue..."
done
