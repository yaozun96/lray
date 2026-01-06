import {ref} from 'vue'
import {defineStore} from 'pinia'

export const useInfoStore = defineStore('info', () => {
  const Token = ref()
 
 function Set_Token(data){
    Token.value=data
  }

  return {
      Token,
      Set_Token
  }
},{ persist:true })
