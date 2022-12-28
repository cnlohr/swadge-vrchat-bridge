﻿
using UdonSharp;
using UnityEngine;
using VRC.SDK3.Components.Video;
using VRC.SDK3.Video.Components;
using VRC.SDK3.Video.Components.AVPro;
using VRC.SDK3.Video.Components.Base;
using VRC.SDKBase;
using VRC.Udon;
using VRC.Udon.Common;

using UnityEngine.UI;

public class H264funButton : UdonSharpBehaviour
{
	public VRCAVProVideoPlayer unityVideo;
	public GameObject stealTextureFrom;
	public GameObject putTextureOn;
	public Material putTextureOnMat;
	public Material CopyMat;
	public Material CopyMat2;
	public Text textOut;
	private int interact_count;
    public VRCUrl _videoURL;

    void Start()
    {
		if (Utilities.IsValid(unityVideo))
		{
			unityVideo.Loop = false;
			unityVideo.Stop();
			unityVideo.EnableAutomaticResync = false;
		}
		Interact();
    }
	
	public override void Interact()
	{
		interact_count++;
		Debug.Log( "Play!" );
		if( unityVideo.IsPlaying )
		{
			unityVideo.Stop();
		}
		else
		{
#if !UNITY_EDITOR
			unityVideo.LoadURL( _videoURL );
#endif
			unityVideo.Play();
		}
	}
	
	void Update()
	{
		float time = -2;
		if (Utilities.IsValid(unityVideo))
		{
			time = unityVideo.GetTime();
		}
		textOut.text = $"Unity Video\nTime: {time}\nPlaying: {unityVideo.IsPlaying}\nCount: {interact_count}";
		putTextureOn.GetComponent<Renderer>().material.SetTexture( "_MainTex", stealTextureFrom.GetComponent<Renderer>().material.GetTexture("_MainTex") );
		putTextureOnMat.SetTexture( "_MainTex", stealTextureFrom.GetComponent<Renderer>().material.GetTexture("_MainTex") );
		CopyMat.SetTexture( "_MainTex", stealTextureFrom.GetComponent<Renderer>().material.GetTexture("_MainTex") );
		CopyMat2.SetTexture( "_MainTex", stealTextureFrom.GetComponent<Renderer>().material.GetTexture("_MainTex") );
	}
	
}
