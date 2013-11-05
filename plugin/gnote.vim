if !has("python")
    echo "Error:no python supported!"
    finish
endif


function! Gnote()

let s:mail_host = exists('g:gnote_mail_host') ? g:gnote_mail_host : 'imap.google.com'
let s:mail_port = exists('g:gnote_mail_port') ? g:gnote_mail_port : 993
python << EOF

import imaplib
from email.message import Message
import vim
import os

class Gmail(object):
    IMAP_SERVER = vim.eval('s:mail_host')
    IMAP_PORT   = vim.eval('s:mail_port')
    print 'establish connect to ', IMAP_SERVER , '...'

    def __init__(self,usr,pwd):
        self.usr = usr
        self.pwd = pwd
        self.hld = imaplib.IMAP4_SSL(self.IMAP_SERVER,self.IMAP_PORT)
        self.status = 0

    def login(self):
        rc,res = self.hld.login(self.usr,self.pwd)
        code = self.checkcode(res)
        if code == True:
            self.status = 1
        return code

    @staticmethod
    def checkcode(code):
        code = str(code).upper()
        if 'OK' in code:
            return True
        else:
            return False

    def __del__(self):
        if self.status == 1:
            self.hld.logout()

    def addbox(self,mailbox):
        rc,res = self.hld.create(mailbox)
        code = self.checkcode(rc)
        return code

    def delbox(self,mailbox):
        rc,res = self.hld.delete(mailbox)
        code   = self.checkcode(rc)
        return code

    def modbox(self,oldbox,newbox):
        rc,res = self.hld.rename(oldbox,newbox)
        code = self.checkcode(rc)
        return code

    def addnote(self,mailbox,content, subject):
        msg = Message()
        msg['Subject'] = subject
        msg['From'] = self.usr.split('@')[0]
        msg.set_payload(content)
        rc,res  = self.hld.append(mailbox,None,None,msg.as_string())
        code = self.checkcode(rc)
        return code


def main():
    user = vim.eval('g:gnote_mail_username')
    pawd = vim.eval('g:gnote_mail_password')
    mailbox = vim.eval('g:gnote_mail_mailbox').strip() or 'gnote'
    bsname = os.path.basename(vim.eval('expand("%")'))
    mbox = bsname.strip('.').split('.')
    subject = os.path.basename(mbox[0])
    mailbox = mailbox or mbox[0]
    gmail = Gmail(user,pawd)
    gmail.login()
    try:
        gmail.addbox(mailbox)
    except:
        pass

    note = '\r\n'.join(vim.current.buffer[:])
    code = gmail.addnote(mailbox,note,subject)
    if code == True:
        print 'send to %s successful!'%mailbox
    else:
        print 'send failed!'

if __name__ == '__main__':
    main()

EOF
endfunction
