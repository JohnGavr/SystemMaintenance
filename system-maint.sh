#!/bin/bash

#System Maintenance Script for Debian based systems
#Συντήρηση λειτουργικού συστήματος βασισμένο στην διανομή Debian και τα παράγωγα της.
#Authors: JohnGavr, GNUTechie

echo "Συντήρηση Λειτουργικού Συστήματος"

#Μεταβλητές που ελέγχουν αν οι λειτουργείες έχουν εκτελεστεί.
disable_old_kernel_deletion=0
disable_cache_deletion=0
disable_unused_packages_deletion=0


delete_unused_packages () {
 echo "Διαγραφή αχρείαστων πακέτων."
 if [[ $disable_unused_packages_deletion -eq 1  ]]
    then
      echo "Η λειτουργία διαγραφής αχρείαστων πακέτων έχει ήδη εκτελεστεί."
    else
      echo "Με την επιλογή αυτή θα αφαιρεθούν τα πακέτα που δεν χρειάζονται ούτε σαν εξαρτήσεις αλλά ούτε και από το ίδιο το σύστημα."
      echo "Εισάγεται τον κωδικό του συστήματος για την διαγραφή των αχρείαστων πακέτων."
      
      #This terminal command used to remove packages that were automatically installed to satisfy dependencies for some package and no longer needed by those packages.
      sudo apt-get autoremove

      #This terminal command deletes all .deb files from /var/cache/apt/archives. It basically cleans up the apt-get cache.
      #sudo apt-get autoclean
      #This terminal command is used to free up the disk space by cleaning up downloaded .deb files from the local repository.
      #sudo apt-get clean
fi

}


delete_cache () {
 echo "Διαγραφή της cache του συστήματος"

 #Εαν η μεταβλητη disable_cache_deletion ειναι 1 τοτε δεν θα εκτελεστει η εντολη και δεν γινεται διαγραφη της cache του συστηματος για
 #παραπανω απο μια φορα.

 if [[ $disable_cache_deletion -eq 1  ]]
    then
       echo "Η λειτουργεια διαγραφης της cache του συστηματος εχει ηδη χρησιμοποιηθει. Δεν υπαρχει λογος κλησης της."
    else
       echo "Στοιχεια μνημης συστηματος πριν την διαγραφη της cache"
       free -m
       #Διαγραφή των cache του συστήματος
       echo "Εκτελεση εντολης διαγραφης της cache"
       echo ""
       sudo sh -c 'sync ; echo 3 >/proc/sys/vm/drop_caches'
       echo ""
       echo "Στοιχεια μνημης συστηματος μετα την διαγραφη της cache"
       free -m
fi
}


delete_old_kernels () {
#Διαγραφη Παλιών Kernel. Αποθήκευση αποτελεσμάτων στην μεταβλητή old_kernels
  #Αν η μεταβλητη disable_kernel_detection ειναι ιση η μεγαλητερη απο το 1 τοτε δεν εκτελειται η εντολη και δεν γινεται ελεγχος
  #για παλαιοτερα kernels στο συστημα.
  if [[ $disable_old_kernel_deletion -eq 1 ]]
     then
         echo "H λειτουργία διαγραφής παλιών kernel έχει ήδη εκτελεστεί."
     else
   old_kernels=$( dpkg -l | tail -n +6 | grep -E 'linux-image-[0-9]+' | grep -Fv $(uname -r) )

   #Εαν η old_kernels ειναι αδεια (δηλαδη δεν βρεθει περιεχομενο απλα εκτυπωσε το αναλογο μήνυμα
   #στην οθόνη, αλλιως σβησε το καθε παλιο kernel που βρεθηκε ενα προς ενα.
   if [[ $old_kernels == "" ]]
      then
          echo "Δεν βρέθηκαν παλαιότερα kernel στο σύστημα σας. Δεν χρειάζονται περαιτέρω ενέργειες."
      else
         #Εφόσον βρεθηκαν παλιοτερα kernels τοτε διαβασε τα αποτελεσματα γραμμη γραμμη και διαβασε το ονομα του πακετου
         #απο την καθε γραμμη ετσι ωστε να ενσωματωθεί στην εντολη διαγραφης.
         echo "Βρέθηκαν παλαιότερα kernels. Θα αφαιρεθούν το ένα μετά το άλλο."
          while read line;
             do
              sudo apt-get -y purge $(echo ${line}| awk 'BEGIN {FS=" "}{print $2}');
             done <<< "$old_kernels"
   fi
fi
}



# PS3 εμφανίζει μήνυμα για την εντολή που επιλέγεις να τρέξεις
PS3='Καλωοσρίσατε στο πρόγραμμα εκαθθάρισης του συστήματος.
     Μπορείτε να διαλέξετε μια από τις επιλογές : '
# Options menu
options=("Διαγραφή Παλιών Kernel" "Διαγραφή Cache" "Διαγραφή αχρείαστων πακέτων" "Όλα τα παραπάνω" "Έξοδος")

# Cases για την κάθε επιλογή ξεχωριστά

select opt in "${options[@]}"
do
    case $opt in
        "Διαγραφή Παλιών Kernel")
            delete_old_kernels
             disable_old_kernel_deletion=1 ;;
        "Διαγραφή Cache")
            delete_cache
            disable_cache_deletion=1 ;;
        "Διαγραφή αχρείαστων πακέτων")
           delete_unused_packages
           disable_unused_packages_deletion=1 ;;
        "Όλα τα παραπάνω")
           delete_old_kernels
           disable_old_kernel_deletion=1
           delete_cache
           disable_cache_deletion=1
           delete_unused_packages
           disable_unused_packages_deletion=1 ;;
        "Έξοδος")
            echo "Έξοδος"
            exit 0
    ;;
  *)
  echo "Ξανά..."
     esac
done


exit 0
