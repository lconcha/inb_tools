#!/bin/bash
source `which my_do_cmd`

####################################
# IMPORTANT NOTE:
# Make sure that ogawa is running storescp.
# There is a service in ogawa configured by /etc/systemd/system/storescp-ogawa.service
# In ogawa, use sudo service storescp-ogawa start to start the service, and sudo service storescp-ogawa status to check in on it.
# The output directory for the storescp-ogawa is /misc/tesla3/dicomdump
#####################################


usage() {
  echo ""
  echo "Usage: $0 [-a|--all] PATIENT_ID"
  echo "  -a, --all    retrieve all series for each study, not only T1 images"
  echo ""
  echo "Useful info:"
  echo " + Images will be saved to /misc/tesla3/dicomdump/PATIENTNAME_DATE_TIME/"
  echo " + PATIENT_ID is dicom tag (0010,0020) LO [85690] #   6, 1 PatientID"
  echo ""
  echo "LU15 (0N(H4"
  echo "INB UNAM"
  echo "April 2026"
  exit 1
}

FETCH_ALL=0
ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all)
      FETCH_ALL=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -z "$ID" ]]; then
        ID="$1"
        shift
      else
        echo "Unexpected argument: $1"
        usage
      fi
      ;;
  esac
done

if [[ -z "$ID" ]]; then
  usage
fi

total_moved=0

move_series() {
  local study_uid=$1
  local series_uid=$2
  echolor bold "            ✓ Fetching SeriesInstanceUID=${series_uid} from StudyInstanceUID=${study_uid}"
  movescu  -S \
    -aec SYNUNAMJ \
    -aet ogawa_dcm \
    -aem ogawa_dcm \
    -k "QueryRetrieveLevel=SERIES" \
    -k "StudyInstanceUID=${study_uid}" \
    -k "SeriesInstanceUID=${series_uid}" \
    192.168.192.111 104
}

move_series_with_sr() {
  local study_uid=$1
  local series_uid=$2
  local sr_series_uid=$3

  move_series "$study_uid" "$series_uid"

  if [[ -n "$sr_series_uid" ]]; then
    echolor bold "            ✓ Fetching SR SeriesInstanceUID=${sr_series_uid} from StudyInstanceUID=${study_uid}"
    movescu  -S \
      -aec SYNUNAMJ \
      -aet ogawa_dcm \
      -aem ogawa_dcm \
      -k "QueryRetrieveLevel=SERIES" \
      -k "StudyInstanceUID=${study_uid}" \
      -k "SeriesInstanceUID=${sr_series_uid}" \
      192.168.192.111 104
  fi
}

get_sr_series_uids() {
  local series_info=$1
  printf '%s' "$series_info" | \
    awk -F'[][]' '
      /^D: DcmDataset::read/ { uid=""; desc=""; next }
      /\(0020,000e\)/ { uid=$2 }
      /\(0008,103e\)/ { desc=$2 }
      uid != "" && desc != "" {
        if (desc ~ /FUJI Basic Text SR/) print uid
        uid=""; desc=""
      }
    ' | head -1
}

get_series_descriptions() {
  local series_info=$1
  mapfile -t series_pairs < <(printf '%s' "$series_info" | \
    awk -F'[][]' '
      /^D: DcmDataset::read/ { uid=""; desc=""; next }
      /\(0020,000e\)/ { uid=$2 }
      /\(0008,103e\)/ { desc=$2 }
      uid != "" && desc != "" { print uid "\t" desc; uid=""; desc="" }
    ')

  printf '  Found %s series\n' "${#series_pairs[@]}"
  echo ""
  if [ $FETCH_ALL -eq 1 ]; then
    echolor cyan "  All series will be retrieved."
    echo ""
  else
    echolor cyan "  Only T1 series will be retrieved."
    echo ""
  fi
  
  for pair in "${series_pairs[@]}"; do
    series_uid=${pair%%$'\t'*}
    desc=${pair#*$'\t'}
    
    prefix="           "
    if [[ "$FETCH_ALL" -eq 1 || "$desc" == *T1* ]]; then
      if [[ "$FETCH_ALL" -eq 0 && "$desc" =~ (Gd|GD|Gadolinium|Gadolinio|Gadolineo|gd) ]]; then
        prefix="      (Gd) "
        printf '%s%s | SeriesInstanceUID=%s\n' "$prefix" "$desc" "$series_uid"
      else
        prefix="      -->  "
        SeriesToFetch+=("$series_uid")
        printf '%s%s | SeriesInstanceUID=%s\n' "$prefix" "$desc" "$series_uid"
        sr_uid=$(get_sr_series_uids "${SeriesInfo}")
        move_series_with_sr "${uid}" "${series_uid}" "${sr_uid}"
        ((total_moved++))
      fi
    else
        prefix="           "
        printf '%s%s | SeriesInstanceUID=%s\n' "$prefix" "$desc" "$series_uid"
    fi
  done
}


# Here we find all studies for a given patient with PatientID equal to the first argument to the script.
mapfile -t StudyInstanceUIDs < <(findscu -v -d -S \
  -aec SYNUNAMJ \
  -aet ogawa_dcm \
  -k "QueryRetrieveLevel=STUDY" \
  -k "StudyInstanceUID" \
  -k "PatientName" \
  -k "StudyDate" \
  -k "StudyDescription" \
  -k "AccessionNumber" \
  -k "PatientID=${ID}" \
  192.168.192.111 104 2>&1 | \
  perl -0777 -ne 'while(/D: \(0020,000d\) UI \[([^\]]+)\]/sg){print "$1\n"}')


# For each of the studies of a given patient, find all the series and their descriptions, and print them out.
for uid in "${StudyInstanceUIDs[@]}"; do
  SeriesToFetch=()
  StudyDate=$(findscu -v -d -S \
    -aec SYNUNAMJ \
    -aet ogawa_dcm \
    -k "QueryRetrieveLevel=STUDY" \
    -k "StudyInstanceUID=${uid}" \
    -k "StudyDate" \
    192.168.192.111 104 2>&1 | \
    perl -0777 -ne 'if(/D: \(0008,0020\) DA \[([^\]]+)\]/s){print "$1\n"; exit}')

  StudyDescription=$(findscu -v -d -S \
    -aec SYNUNAMJ \
    -aet ogawa_dcm \
    -k "QueryRetrieveLevel=STUDY" \
    -k "StudyInstanceUID=${uid}" \
    -k "StudyDescription" \
    192.168.192.111 104 2>&1 | tr -d '\000' | \
    perl -0777 -ne 'if(/D: \(0008,1030\) LO \[([^\]]+)\]/s){print "$1\n"; exit}')

  SeriesInfo=$(findscu -v -d -S \
    -aec SYNUNAMJ \
    -aet ogawa_dcm \
    -k "QueryRetrieveLevel=SERIES" \
    -k "StudyInstanceUID=${uid}" \
    -k "SeriesInstanceUID" \
    -k "SeriesDescription" \
    -k "Modality" \
    192.168.192.111 104 2>&1 | tr -d '\000' )



  echolor green "STUDY: ${StudyDate} | ${StudyDescription} | ${uid}"
  get_series_descriptions "${SeriesInfo}"
  echolor bold "  Total series moved for this subjectID: ${total_moved}"
done