execute 'add unspecified mount to fstab' do
  command 'echo "fs-fedc4321.efs.us-west-2.amazonaws.com:/ /mnt/foo nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 2" >> /etc/fstab'
end
