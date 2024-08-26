#!/bin/bash
source `which my_do_cmd`
fakeflag=""

print_help(){
echo "
Utiliza este script para cambiar parámetros de XDG y así acelerar tu sesión gráfica en el cluster.

Uso: `basename $0` </misc/DISCO/USUARIO/newXDG>

Donde newXDG representa una carpeta en un lugar de /misc donde tienes permisos de escritura.
Se recomienda que la carpeta se llame XDG, por ejemplo /misc/mansfield/${USER}/XDG

"
}


scpresume='rsync -avz --partial --progress --rsh=ssh'


if [ $# -lt 1 ]
then
  echolor red "ERROR, need one argument"
  print_help
  exit 2
fi


newXDG=$1
newXDG=$(echo "$newXDG" | sed 's:/*$::'); # remove trailing slash

if [ -z "${newXDG}" ]
then
  echolor red "Debes especificar una carpeta en /misc"
  print_help
  exit 2
fi

mkdir -p ${newXDG}/.local/{share,state} || exit 2

my_do_cmd $fakeflag $scpresume ~/.config ${newXDG}/
my_do_cmd $fakeflag $scpresume ~/.cache  ${newXDG}/
my_do_cmd $fakeflag $scpresume ~/.local/share ${newXDG}/.local/
my_do_cmd $fakeflag $scpresume ~/.local/state ${newXDG}/.local/

if [ -f ~/.pam_environment ]
then
  my_do_cmd $fakeflag cp ~/.pam_environment ~/.pam_environment.bak
  my_do_cmd $fakeflag sed -i s/^XDG_CONFIG_HOME/\#XDG_CONFIG_HOME/g ~/.pam_environment  
  my_do_cmd $fakeflag sed -i s/^XDG_CACHE_HOME/\#XDG_CACHE_HOME/g ~/.pam_environment  
  my_do_cmd $fakeflag sed -i s/^XDG_DATA_HOME/\#XDG_DATA_HOME/g ~/.pam_environment  
  my_do_cmd $fakeflag sed -i s/^XDG_STATE_HOME/\#XDG_STATE_HOME/g ~/.pam_environment  
fi

echo XDG_CONFIG_HOME=${newXDG}/.config     >> ~/.pam_environment
echo XDG_CACHE_HOME=${newXDG}/.cache       >> ~/.pam_environment
echo XDG_DATA_HOME=${newXDG}/.local/share  >> ~/.pam_environment
echo XDG_STATE_HOME=${newXDG}/.local/state >> ~/.pam_environment

cat ~/.pam_environment

# Nos encargamos de carpetas de configuración que no siguen el estándar XDG
carpetas=".matlab .zoom .inkscape .imagej .vscode .zotero"
for carpeta in $carpetas
do
  echo "Moviendo ${HOME}/$carpeta a $newXDG y creando un symlink..."
  if [ -L ${HOME}/$carpeta ]
  then 
    echolor green "  Esta carpeta es un link, no vamos a moverla: ${HOME}/$carpeta"
    continue
  fi
  #du -hs $carpeta
  cp -rv ${HOME}/$carpeta ${newXDG}/
  #echo mv -v ${HOME}/$carpeta ${carpeta}.bak
  echo ln -s ${newXDG}/${carpeta} ${HOME}/$carpeta
  echo "" 
done

for f in ~/.bash_profile ~/.bash_login
do
  if [ -f $f ]
  then
    echolor orange "[ADVERTENCIA] Tienes archivo $f."
    echolor orange "              Necesitas borrarlo (pasa su contenido a ~/.bashrc)"
    echolor orange "              Si no lo haces, tu sesión gráfica no podrá ser acelerada."
  fi
done

if [ ! -f ~/.profile ]
then
  echo "Creando ~/.profile"
  echo "#!/bin/bash" > ~/.profile
fi

thisfilepath=$(dirname $0)
cat  ${thisfilepath}/inb_check_XDG.txt >> ~/.profile


echolor cyan "Listo. Debes cerrar y abrir tu sesión para que surta efecto."
