from collections import defaultdict
import re

class DictMaster:

    pMultiSpaces = re.compile('[\s]{2,}')
    
    def __init__(self, sPhonemesFile, sNonPhonesFile='', case='upper'):
        #TODO handle file not found error
        self.case = case
        with open(sPhonemesFile,'r') as fPhonemeList:
            self.lPhonemes = fPhonemeList.read().splitlines()
        self.dLenPhone = defaultdict(list)
        for sPhone in self.lPhonemes:
            self.dLenPhone[len(sPhone)].append(sPhone)
        if sNonPhonesFile:
            with open(sNonPhonesFile,'r') as fNonPhones:
                self.dLenPhone[0] = fNonPhones.read().splitlines()


    #Dict should be tab separated value
    def loadDict(self, sDictFile, case='lower', sMapFile = '', bAddBndr = True, bValidate=True):
        dLexicon = defaultdict(list)
        
        if self.case == 'upper':
            mapper = lambda x : x.upper()
        else:
            mapper = lambda x : x.lower()
        
        with open(sDictFile,'r') as fDict:
            
            for sLine in fDict.read().splitlines():
                #print(sLine)
            
                lLines = sLine.split('\t')
                sWord = lLines[0]
                lTrans = lLines[1:]

                #TODO: print list of the word changed
                sWord = re.sub('(?<=\S)[ ]+(?=\S)', '-' ,sWord)
                
                dLexicon[mapper(sWord)].extend([sTrans.strip() for sTrans in lTrans if sTrans !=''])
        if bAddBndr:
            dLexicon = self.addPhoneBoundry(dLexicon)
        if sMapFile:
            #dLexicon = self.mapPhone(dLexicon, sMapFile)
            dLexicon = self.mapPhone(dLexicon, sMapFile)#, bAddBndr)
        if self.dLenPhone[0]:
            dLexicon = self.CleanTrans(dLexicon)
        if bValidate:
            self.Validate(dLexicon)        
        return(dLexicon)


    def mapPhone(self, dLexicon, sMapFile, bAddBndr = False):
        
        dLexicon_map = defaultdict(set)

        dMapPhone = defaultdict(dict)

        with open(sMapFile,'r') as fMap:
            for sLine in fMap.read().splitlines():
                k,v = sLine.split()
                dMapPhone[len(k.strip())][k] = v.strip()

        def repl_lr(x):
            match = x.group(0)
            iLen = len(match)
            sMapped = dMapPhone[iLen][match]
            if bAddBndr:
                sMapped = ' ' + sMapped + ' '
            return sMapped

        def repl_rl(x):
            match = x.group(0)
            iLen = len(match)
            sMapped = dMapPhone[iLen][match[::-1]][::-1]
            if bAddBndr:
                sMapped = ' ' + sMapped + ' '
            return sMapped

        lLenths = list(dMapPhone.keys())
        lLenths.reverse() 

        lOrgPhones = []

        for i in lLenths:
            lOrgPhones.extend(dMapPhone[i])
            
        rPtrn_lr = re.compile('|'.join([re.escape(x) for x in lOrgPhones]))
        rPtrn_rl = re.compile('|'.join([re.escape(x[::-1]) for x in lOrgPhones]))

        for sWord in dLexicon:
            for trans in dLexicon[sWord]:
                trans_lr = rPtrn_lr.sub(repl_lr,trans)
                trans_rl = rPtrn_rl.sub(repl_rl,trans[::-1])
                if trans_lr != trans_rl[::-1]:
                    print('ambiguity in {} with trans {} could be {} or {}'.format(sWord, trans, trans_lr, trans_rl[::-1]))
                trans = self.pMultiSpaces.sub(' ',trans_lr)
                dLexicon_map[sWord].add(trans.strip())
        return dLexicon_map

    #TODO implement with regex
    #TODO add ambiguation check
    #Assuming here that phoneme symboles are either 1 or 2
    def addPhoneBoundry(self,dLexicon):
        
        dLexicon_PBd = defaultdict(set)

        for sWord in dLexicon:
            for trans in dLexicon[sWord]:
                i = 0
                while i < len(trans):
                    if trans[i:i+2] in self.dLenPhone[2]:
                        trans = trans[:i] +' '+trans[i:i+2]+' '+trans[i+2:]
                        i += 4
                    elif trans[i] in self.dLenPhone[1]:
                        trans = trans[:i] +' '+trans[i:i+1]+' '+trans[i+1:]
                        i += 3
                    else:
                        i += 1
                   #     trans = trans[:i] +' '+trans[i:i+1]+' '+trans[i+1:]
                   #     i += 3
                trans = self.pMultiSpaces.sub(' ',trans)

                dLexicon_PBd[sWord].add(trans.strip())
                
        return dLexicon_PBd


    def CleanTrans(self, dLexicon):
        dLexicon_Clean = defaultdict(set)

        if not self.dLenPhone[0]:
            return dLexicon
        p = re.compile('|'.join(map(re.escape,self.dLenPhone[0])))

        for sWord in dLexicon:
            for trans in dLexicon[sWord]:
                trans = p.sub('',trans)
                trans = self.pMultiSpaces.sub(' ',trans)
                dLexicon_Clean[sWord].add(trans.strip())

        return dLexicon_Clean

    #Assuming that trans has already phoneme boundries
    #TODO write log file with errors
    def Validate(self, dLexicon):
        for sWord in dLexicon:
            for trans in dLexicon[sWord]:
                for sPhone in trans.split():
                    if sPhone not in self.lPhonemes:
                        print('Word: {} with trans: {} has phoneme {} not in phoneme symbols'.format(sWord, trans, sPhone))
        return


    #TODO How to handle multiple trans of same word
    def WriteDict(self, dLexicon, sOutputFile, bRmBnrdy=False, sDelimiter = '\t', sCase = 'upper'):
        with open(sOutputFile,'w') as fOut:
            for sWord in dLexicon:
                sWord_ToWrite = sWord.lower() if (sCase == 'lower') else sWord.upper()
                for trans in dLexicon[sWord]:
                    trans = trans.replace(' ','') if bRmBnrdy else trans
                    print('{}{}{}'.format(sWord_ToWrite,sDelimiter,trans), file = fOut)
        return



    
    #TODO add dict to same class
    #TODO Get subset from dict
    def SearchDict(self, sWordListFile, lLexicon):
        
        dLexicon = self.MergeDict(lLexicon)

        dLexicon_out = defaultdict(set)
        
        lUnknownWords = []

        with open(sWordListFile,'r') as fWrdList:
            for sWord in fWrdList.read().splitlines():
                sWord = sWord.lower() if (self.case == 'lower') else sWord.upper()
                if sWord not in dLexicon:
                    lUnknownWords.append(sWord)
                else:
                    dLexicon_out[sWord] = dLexicon[sWord]

        return dLexicon_out, lUnknownWords



    def MergeDict(self, lLexicon):
        
        dLexicon_merg = defaultdict(set)
        
        for dLexicon in lLexicon:
            
            for k,v in dLexicon.items():
                dLexicon_merg[k].update(v)

        return dLexicon_merg











