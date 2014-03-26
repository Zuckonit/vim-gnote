scriptencoding utf-8

if !has("python")
    echo "Error: your vim has no python supported!"
    finish
endif


au BufRead,BufNewFile {*.md,*.mkd,*.markdown} set ft=markdown
function! Gnote()

let s:mail_host = exists('g:gnote_mail_host') ? g:gnote_mail_host : 'imap.gmail.com'
let s:mail_port = exists('g:gnote_mail_port') ? g:gnote_mail_port : 993
let s:auto_convert_mkd = exists('g:gnote_auto_convert_markdown') ? g:gnote_auto_convert_markdown : 0

python << EOF
#-*- coding:utf-8 -*-
import imaplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import vim
import os

class Gmail(object):
    IMAP_SERVER = vim.eval('s:mail_host')
    IMAP_PORT   = vim.eval('s:mail_port')
    print 'establish connect to', IMAP_SERVER , '...'

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
        return True if 'OK' in code else False

    def logout(self):
        if self.status == 1:
            print self.hld.logout()[0]

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

    def addnote(self,mailbox,content, subject, fmt=None):
        if fmt is None:
            fmt = 'plain'
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = self.usr.split('@')[0]
        content = MIMEText(content ,fmt)
        msg.attach(content)
        rc,res  = self.hld.append(mailbox,None,None,msg.as_string())
        code = self.checkcode(rc)
        return code

def read_input(message='input'):
    vim.command('call inputsave()')
    vim.command("let user_input = input('" + message + ": ')")
    vim.command('call inputrestore()')
    vim.command('redraw')
    return vim.eval('user_input')

def main():
    user = vim.eval('g:gnote_mail_username')
    pawd = vim.eval('g:gnote_mail_password')
    mailbox = vim.eval('g:gnote_mail_mailbox').strip() or 'gnote'
    bsname = os.path.basename(vim.eval('expand("%")'))
    mbox = bsname.strip('.').split('.')
    subject = os.path.basename(mbox[0])
    if not subject:
        subject = read_input("Subject")
    mailbox = mailbox or mbox[0]
    note = '\r\n'.join(vim.current.buffer[:])
    fmt=None
    if vim.eval('&filetype') == 'markdown':
        if vim.eval('s:auto_convert_mkd') == '1':
            try:
                import markdown
                note = unicode(note, 'utf-8')
                note = markdown.markdown(note).encode('utf-8')
                fmt = 'html'
            except ImportError:
                print "no module named  markdown"
                import sys
                sys.exit(1)
    
    gmail = Gmail(user,pawd)
    gmail.login()
    try:
        gmail.addbox(mailbox)
    except:
        pass
    code = gmail.addnote(mailbox,note,subject,fmt)
    print 'send to %s successful!'%mailbox if code == True else 'send failed'
    gmail.logout()

if __name__ == '__main__':
    main()
EOF
endfunction
